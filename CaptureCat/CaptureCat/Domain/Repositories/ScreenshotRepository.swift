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
    
    // MARK: - Local Only Operations (비로그인 모드)
    
    private func loadFromLocal() throws -> [ScreenshotItemViewModel] {
        let ents = try SwiftDataManager.shared.fetchAllEntities()
        let items = ents.map { ent in
            ScreenshotItem(
                id: ent.id,
                imageData: Data(),
                fileName: ent.fileName,
                createDate: ent.createDate,
                tags: ent.tags,
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
                tags: ent.tags,
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
                tags: ent.tags,
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
            let serverItems = response.data.items.compactMap { serverItem -> ScreenshotItem? in
                guard let captureDate = parseServerDate(serverItem.captureDate) else {
                    return nil
                }
                
                let mappedTags = serverItem.tags.map { $0.name }
                
                let screenshotItem = ScreenshotItem(
                    id: String(serverItem.id),
                    imageData: Data(), // 서버 URL에서 별도 로드
                    imageURL: serverItem.url, // ✅ 서버 이미지 URL 포함
                    fileName: serverItem.name,
                    createDate: captureDate,
                    tags: mappedTags, // ✅ 매핑된 태그 사용
                    isFavorite: serverItem.isBookmarked
                )
                
                return screenshotItem
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
            let serverItems = response.data.items.compactMap { serverItem -> ScreenshotItem? in
                guard let captureDate = parseServerDate(serverItem.captureDate) else {
                    return nil
                }
                
                let mappedTags = serverItem.tags.map { $0.name }
                
                let screenshotItem = ScreenshotItem(
                    id: String(serverItem.id),
                    imageData: Data(), // 서버 URL에서 별도 로드
                    imageURL: serverItem.url, // ✅ 서버 이미지 URL 포함
                    fileName: serverItem.name,
                    createDate: captureDate,
                    tags: mappedTags, // ✅ 매핑된 태그 사용
                    isFavorite: serverItem.isBookmarked
                )
                
                return screenshotItem
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
        // 🚫 서버에 태그 업데이트 전송 임시 비활성화
        // try await addTagToServer(id: viewModel.id, tags: viewModel.tags)
        
        // 메모리 캐시 업데이트
        InMemoryScreenshotCache.shared.store(viewModel)
        
        debugPrint("✅ 서버 전용 저장 완료 (태그 서버 전송 제외): \(viewModel.fileName)")
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
    
    // 🚫 서버 태그 추가 기능 임시 비활성화
    /*
     /// 특정 이미지에 태그 추가 (서버)
     func addTagToServer(id: String, tags: [String]) async throws {
     let result = await ImageService.shared.addImage(tags: tags, id: id)
     
     switch result {
     case .success:
     debugPrint("✅ 서버에 태그 추가 성공: \(tags)")
     case .failure(let error):
     debugPrint("❌ 서버에 태그 추가 실패: \(error)")
     throw error
     }
     }
     */
    
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
        viewModel.tags = model.tags
        viewModel.isFavorite = model.isFavorite
    }
    
    func fetchViewModels(for ids: [String]) -> [ScreenshotItemViewModel] {
        return ids.compactMap { self.vms[$0] }
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
    
    func renameTag(from oldName: String, to newName: String) async throws {
        if AccountStorage.shared.isGuest ?? true {
            try SwiftDataManager.shared.renameTag(from: oldName, to: newName)
        } else {
            // 로그인 모드에서는 메모리 캐시 업데이트만
            let items = InMemoryScreenshotCache.shared.retrieveAll()
            for item in items {
                if item.tags.contains(oldName) {
                    item.removeTag(oldName)
                    item.addTag(newName)
                }
            }
        }
    }
}
