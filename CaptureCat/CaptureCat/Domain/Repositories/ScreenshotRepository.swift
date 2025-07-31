//
//  ScreenshotRepository.swift
//  CaptureCat
//
//  Created by minsong kim on 7/20/25.
//

import Foundation
import Photos

@MainActor
final class ScreenshotRepository {
    static let shared = ScreenshotRepository()
    private var vms: [String: ScreenshotItemViewModel] = [:]
    
    private init() {}
    
    // MARK: - Smart Loading (로그인/비로그인 자동 분기)
    
    /// 로그인 상태에 따라 자동으로 로컬 또는 서버에서 로드
    func loadAll() throws -> [ScreenshotItemViewModel] {
        if AccountStorage.shared.isGuest ?? true {
            return try loadFromLocal()
        } else {
            return InMemoryScreenshotCache.shared.retrieveAll()
        }
    }
    
    /// 특정 태그로 필터링 (로그인 상태 자동 분기)
    func loadByTag(_ tag: String) throws -> [ScreenshotItemViewModel] {
        if AccountStorage.shared.isGuest ?? true {
            return try loadByTagFromLocal(tag)
        } else {
            return InMemoryScreenshotCache.shared.getItemsByTag(tag)
        }
    }
    
    /// 여러 태그로 필터링 (로그인 상태 자동 분기)
    func loadByTags(_ tags: [String]) async throws -> [ScreenshotItemViewModel] {
        if AccountStorage.shared.isGuest ?? true {
            return try loadByTagsFromLocal(tags)
        } else {
            return try await loadByTagsFromServer(tags)
        }
    }
    
    /// 연관 태그 가져오기 (로그인 상태 자동 분기)
    func fetchOtherTagsFromScreenshotsContaining(_ tags: [String]) async throws -> [String] {
        if AccountStorage.shared.isGuest ?? true {
            return try SwiftDataManager.shared.fetchOtherTagsFromScreenshotsContaining(tags)
        } else {
            // TagService를 사용하여 서버에서 연관 태그 가져오기
            let result = await TagService.shared.fetchRelatedTagList(page: 0, size: 100, tags: tags)
            
            switch result {
            case .success(let tagDTO):
                // TagDTO에서 태그 이름들을 추출
                let tagNames = tagDTO.data.items.map { $0.name }
                debugPrint("✅ 서버에서 연관 태그 로드 성공: \(tagNames)")
                return tagNames
            case .failure(let error):
                debugPrint("❌ 서버에서 연관 태그 로드 실패: \(error.localizedDescription)")
                // 실패 시 빈 배열 반환
                return InMemoryScreenshotCache.shared.getOtherTags(for: tags)
                
            }
        }
    }
    
    /// 전체 태그 목록 (로그인 상태 자동 분기)
    func fetchAllTags() async throws -> [String] {
        if AccountStorage.shared.isGuest ?? true {
            return try SwiftDataManager.shared.fetchAllTags()
        } else {
            let result = await TagService.shared.fetchPopularTagList()
            
            switch result {
            case .success(let tagDTO):
                return tagDTO.data.items.map { $0.name }
                
            case .failure(let error):
                return InMemoryScreenshotCache.shared.getAllTags()
            }
        }
    }
    
    func updateTag(id: String, tags: [String]) async throws {
        if AccountStorage.shared.isGuest ?? true {
            try SwiftDataManager.shared.updateTag(id: id, tags: tags)
        } else {
            try await updateTagToServer(id: id, tags: tags)
        }
    }
    
    func deleteTag(imageId: String, tagId: String) async throws {
        if AccountStorage.shared.isGuest ?? true {
            try SwiftDataManager.shared.deleteTag(imageId: imageId, tagId: tagId)
        } else {
            let result = await TagService.shared.deleteTag(imageId: imageId, tagId: tagId)
            
            switch result {
            case .success:
                debugPrint("✅ 서버에 태그 삭제 성공: \(tagId)")
            case .failure(let error):
                debugPrint("❌ 서버에 태그 삭제 실패: \(error)")
                throw error
            }
        }
    }
    
    // MARK: - Local Only Operations (비로그인 모드)
    
    private func loadFromLocal() throws -> [ScreenshotItemViewModel] {
        let ents = try SwiftDataManager.shared.fetchAllEntities()
        let items = ents.map { ent in
            ScreenshotItem(
                id: ent.id,
                imageData: Data(),
                fileName: ent.fileName,
                createDate: ent.createDate,
                tags: ent.tags.enumerated().map { index, tagName in
                    Tag(id: index, name: tagName)
                },
                isFavorite: ent.isFavorite
            )
        }
        return items.map(viewModel(for:))
    }
    
    private func loadByTagFromLocal(_ tag: String) throws -> [ScreenshotItemViewModel] {
        let ents = try SwiftDataManager.shared.fetchEntitiesByTag(tag)
        let items = ents.map { ent in
            ScreenshotItem(
                id: ent.id,
                imageData: Data(),
                fileName: ent.fileName,
                createDate: ent.createDate,
                tags: ent.tags.enumerated().map { index, tagName in
                    Tag(id: index, name: tagName)
                },
                isFavorite: ent.isFavorite
            )
        }
        return items.map(viewModel(for:))
    }
    
    private func loadByTagsFromLocal(_ tags: [String]) throws -> [ScreenshotItemViewModel] {
        let ents = try SwiftDataManager.shared.fetchEntitiesByTags(tags)
        let items = ents.map { ent in
            ScreenshotItem(
                id: ent.id,
                imageData: Data(),
                fileName: ent.fileName,
                createDate: ent.createDate,
                tags: ent.tags.enumerated().map { index, tagName in
                    Tag(id: index, name: tagName)
                },
                isFavorite: ent.isFavorite
            )
        }
        return items.map(viewModel(for:))
    }
    
    // MARK: - Server Only Operations (로그인 모드)
    
    /// 서버에서만 로드 (로컬 저장 X)
    func loadFromServerOnly(page: Int = 0, size: Int = 20) async throws -> [ScreenshotItemViewModel] {
        let result = await ImageService.shared.checkImageList(page: page, size: size, hasTags: nil)
        
        switch result {
        case .success(let response):
            let serverItems = response.data.items.map { serverItem in
                ScreenshotItem(serverItem: serverItem)  // 새로운 생성자 사용
            }
            
            let viewModels = serverItems.map(viewModel(for:))
            
            // 메모리 캐시에만 저장 (로컬 저장 X) - 임시 주석처리
            InMemoryScreenshotCache.shared.store(viewModels)
            
            return viewModels
            
        case .failure(let error):
            throw error
        }
    }
    
    private func loadByTagsFromServer(_ tags: [String], page: Int = 0, size: Int = 20) async throws -> [ScreenshotItemViewModel] {
        let result = await ImageService.shared.checkImageList(by: tags, page: page, size: size)
        
        switch result {
        case .success(let response):
            let serverItems = response.data.items.map { serverItem in
                ScreenshotItem(serverItem: serverItem)  // 새로운 생성자 사용
            }
            
            let viewModels = serverItems.map(viewModel(for:))
            
            // 메모리 캐시에만 저장 (로컬 저장 X) - 임시 주석처리
            InMemoryScreenshotCache.shared.store(viewModels)
            
            return viewModels
            
        case .failure(let error):
            throw error
        }
    }
    
    /// 서버에만 저장 (로컬 저장 X)
    func saveToServerOnly(_ viewModel: ScreenshotItemViewModel) async throws {
        // 메모리 캐시 업데이트
        InMemoryScreenshotCache.shared.store(viewModel)
        
        debugPrint("✅ 서버 전용 저장 완료: \(viewModel.fileName)")
    }
    
    /// 서버에만 업로드
    func uploadToServerOnly(viewModels: [ScreenshotItemViewModel]) async throws {
        var imageDatas: [Data] = []
        var imageMetas: [PhotoDTO] = []
        
        for viewModel in viewModels {
            guard let thumbnailData = viewModel.thumbnail?.jpegData(compressionQuality: 0.8) else {
                debugPrint("⚠️ 이미지 데이터 변환 실패: \(viewModel.fileName)")
                continue
            }
            
            imageDatas.append(thumbnailData)
            imageMetas.append(viewModel.toDTO())
        }
        
        guard !imageDatas.isEmpty else {
            debugPrint("⚠️ 업로드할 이미지가 없습니다.")
            return
        }
        
        let result = await ImageService.shared.uploadImages(imageDatas: imageDatas, imageMetas: imageMetas)
        
        switch result {
        case .success:
            // 메모리 캐시에 저장
            InMemoryScreenshotCache.shared.store(viewModels)
            debugPrint("✅ 서버 전용 업로드 성공: \(imageDatas.count)개 이미지")
        case .failure(let error):
            debugPrint("❌ 서버 업로드 실패: \(error)")
            throw error
        }
    }
    
     /// 특정 이미지에 태그 업데이트
    func updateTagToServer(id: String, tags: [String]) async throws {
        let result = await TagService.shared.updateTag(imageId: id, tags: tags)
        
        switch result {
        case .success:
            debugPrint("✅ 서버에 태그 추가 성공: \(tags)")
        case .failure(let error):
            debugPrint("❌ 서버에 태그 추가 실패: \(error)")
            throw error
        }
    }
    
    // MARK: - Common Operations
    
    func viewModel(for model: ScreenshotItem) -> ScreenshotItemViewModel {
        if let existingViewModel = vms[model.id] {
            syncViewModel(existingViewModel, with: model)
            return existingViewModel
        }
        let viewModel = ScreenshotItemViewModel(model: model)
        vms[model.id] = viewModel
        return viewModel
    }
    
    private func syncViewModel(_ viewModel: ScreenshotItemViewModel, with model: ScreenshotItem) {
        viewModel.fileName = model.fileName
        viewModel.createDate = model.createDate
        // 태그가 비어있지 않을 때만 업데이트 (즐겨찾기 API에서 태그 정보 유실 방지)
        if !model.tags.isEmpty {
            viewModel.tags = model.tags
        }
        viewModel.isFavorite = model.isFavorite
    }
    
    func fetchViewModels(for ids: [String]) -> [ScreenshotItemViewModel] {
        return ids.compactMap { self.vms[$0] }
    }
    
    /// 특정 ID로 ScreenshotItemViewModel 가져오기 (로그인 상태 자동 분기)
    func fetchItem(by id: String) async throws -> ScreenshotItemViewModel? {
        if AccountStorage.shared.isGuest ?? true {
            // 게스트 모드: 로컬에서 찾기
            return try fetchItemFromLocal(id: id)
        } else {
            // 로그인 모드: 메모리 캐시에서 먼저 찾고, 없으면 서버에서 로드
            if let cachedItem = InMemoryScreenshotCache.shared.retrieve(id: id) {
                return cachedItem
            } else {
                return try await fetchItemFromServer(id: id)
            }
        }
    }
    
    /// 로컬에서 특정 ID로 아이템 찾기
    private func fetchItemFromLocal(id: String) throws -> ScreenshotItemViewModel? {
        let entities = try SwiftDataManager.shared.fetchAllEntities()
        guard let entity = entities.first(where: { $0.id == id }) else {
            return nil
        }
        
        let item = ScreenshotItem(
            id: entity.id,
            imageData: Data(),
            fileName: entity.fileName,
            createDate: entity.createDate,
            tags: entity.tags.enumerated().map { index, tagName in
                Tag(id: index, name: tagName)
            },
            isFavorite: entity.isFavorite
        )
        
        return viewModel(for: item)
    }
    
    /// 서버에서 특정 ID로 아이템 찾기
    private func fetchItemFromServer(id: String) async throws -> ScreenshotItemViewModel? {
        let result = await ImageService.shared.checkImageDetail(id: id)
        
        switch result {
        case .success(let response):
            let screenshotItem = ScreenshotItem(serverImageData: response.data)  // 새로운 생성자 사용
            
            let viewModel = viewModel(for: screenshotItem)
            
            // 메모리 캐시에 저장
            InMemoryScreenshotCache.shared.store(viewModel)
            
            return viewModel
            
        case .failure(let error):
            throw error
        }
    }
    
    // MARK: - Cache Management
    
    /// 로그아웃 시 메모리 캐시 클리어
    func clearMemoryCache() {
        InMemoryScreenshotCache.shared.clear()
        debugPrint("🗑️ 메모리 캐시 클리어 완료")
    }
    
    // MARK: - Helper Methods
    
    func parseServerDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: dateString) ?? Date()
    }
    
    // MARK: - Legacy Tag Operations
    func addTag(_ tag: String, toIDs ids: [String]) async throws {
        if AccountStorage.shared.isGuest ?? true {
            try SwiftDataManager.shared.addTag(tag, toIDs: ids)
        } else {
            // 로그인 모드에서는 메모리 캐시 업데이트만
            let items = InMemoryScreenshotCache.shared.retrieveAll()
            for item in items where ids.contains(item.id) {
                item.addTag(tag)
            }
        }
    }
    
    func removeTag(_ tag: String, fromIDs ids: [String]) async throws {
        if AccountStorage.shared.isGuest ?? true {
            try SwiftDataManager.shared.removeTag(tag, fromIDs: ids)
        } else {
            // 로그인 모드에서는 메모리 캐시 업데이트만
            let items = InMemoryScreenshotCache.shared.retrieveAll()
            for item in items where ids.contains(item.id) {
                item.removeTag(tag)
            }
        }
    }
    
//    func renameTag(from oldName: String, to newName: String) async throws {
//        if AccountStorage.shared.isGuest ?? true {
//            try SwiftDataManager.shared.renameTag(from: oldName, to: newName)
//        } else {
//            // 로그인 모드에서는 메모리 캐시 업데이트만
//            let items = InMemoryScreenshotCache.shared.retrieveAll()
//            for item in items {
//                if item.tags.contains(oldName) {
//                    item.removeTag(oldName)
//                    item.addTag(newName)
//                }
//            }
//        }
//    }
}

// MARK: - Favorite Management
extension ScreenshotRepository {
    /// 즐겨찾기 추가 (로그인 상태에 따라 분기)
    func uploadFavorite(id: String) async throws {
        if AccountStorage.shared.isGuest ?? true {
            // 게스트 모드: 로컬에만 저장
            try SwiftDataManager.shared.addToFavorites(imageId: id)
            
            // 메모리의 ViewModel도 업데이트
            if let viewModel = vms[id] {
                viewModel.isFavorite = true
            }
            
            debugPrint("✅ 로컬에 즐겨찾기 추가 성공: \(id)")
        } else {
            // 로그인 모드: 서버에 저장
            let result = await FavoriteService.shared.uploadFavorite(id: id)
            
            switch result {
            case .success:
                // 메모리 캐시의 ViewModel도 업데이트
                if let viewModel = vms[id] {
                    viewModel.isFavorite = true
                }
                InMemoryScreenshotCache.shared.updateFavorite(id: id, isFavorite: true)
                
                debugPrint("✅ 서버에 즐겨찾기 추가 성공: \(id)")
            case .failure(let error):
                debugPrint("❌ 서버에 즐겨찾기 추가 실패: \(error)")
                throw error
            }
        }
    }
    
    /// 즐겨찾기 제거 (로그인 상태에 따라 분기)
    func deleteFavorite(id: String) async throws {
        if AccountStorage.shared.isGuest ?? true {
            // 게스트 모드: 로컬에서 제거
            try SwiftDataManager.shared.removeFromFavorites(imageId: id)
            
            // 메모리의 ViewModel도 업데이트
            if let viewModel = vms[id] {
                viewModel.isFavorite = false
            }
            
            debugPrint("✅ 로컬에서 즐겨찾기 제거 성공: \(id)")
        } else {
            // 로그인 모드: 서버에서 제거
            let result = await FavoriteService.shared.deleteFavorite(id: id)
            
            switch result {
            case .success:
                // 메모리 캐시의 ViewModel도 업데이트
                if let viewModel = vms[id] {
                    viewModel.isFavorite = false
                }
                InMemoryScreenshotCache.shared.updateFavorite(id: id, isFavorite: false)
                
                debugPrint("✅ 서버에서 즐겨찾기 제거 성공: \(id)")
            case .failure(let error):
                debugPrint("❌ 서버에서 즐겨찾기 제거 실패: \(error)")
                throw error
            }
        }
    }
    
    /// 즐겨찾기 상태 토글 (로그인 상태에 따라 분기)
    func toggleFavorite(id: String) async throws {
        // 현재 상태 확인
        let currentFavoriteState: Bool
        
        if AccountStorage.shared.isGuest ?? true {
            currentFavoriteState = SwiftDataManager.shared.isFavorite(imageId: id)
        } else {
            currentFavoriteState = vms[id]?.isFavorite ?? false
        }
        
        // 상태에 따라 추가/제거
        if currentFavoriteState {
            try await deleteFavorite(id: id)
        } else {
            try await uploadFavorite(id: id)
        }
    }
    
    /// 즐겨찾기 목록 조회 (로그인 상태에 따라 분기)
    func loadFavorites(page: Int, size: Int) async throws -> [ScreenshotItemViewModel] {
        if AccountStorage.shared.isGuest ?? true {
            // 게스트 모드: 로컬에서 즐겨찾기 조회
            let favoriteEntities = try SwiftDataManager.shared.fetchFavoriteEntities()
            let items = favoriteEntities.map { entity in
                ScreenshotItem(
                    id: entity.id,
                    imageData: Data(),
                    imageURL: nil, // 게스트 모드에서는 로컬 이미지
                    fileName: entity.fileName,
                    createDate: entity.createDate,
                    tags: entity.tags.enumerated().map { index, tagName in
                        Tag(id: index, name: tagName)
                    },
                    isFavorite: entity.isFavorite
                )
            }
            return items.map(viewModel(for:))
        } else {
            return try await loadFavoriteFromServerOnly(page: page, size: size)
        }
    }
    
    func loadFavoriteFromServerOnly(page: Int = 0, size: Int = 20) async throws -> [ScreenshotItemViewModel] {
        let result = await FavoriteService.shared.checkFavoriteImageList(page: page, size: size)
        
        switch result {
        case .success(let response):
            let serverItems = response.data.items.map { favoriteItem in
                ScreenshotItem(favoriteItem: favoriteItem)  // 새로운 생성자 사용
            }
            
            let viewModels = serverItems.map(viewModel(for:))
            
            return viewModels
            
        case .failure(let error):
            throw error
            return InMemoryScreenshotCache.shared.getFavorites()
        }
    }
}
