//
//  DetailViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import SwiftUI

@MainActor
class DetailViewModel: ObservableObject {
    // MARK: - Properties
    @Published var isShowingAddTagSheet: Bool = false
    @Published var tempSelectedTags: Set<String> = []
    @Published var isDeleted: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var item: ScreenshotItemViewModel?
    @Published var isFavorite: Bool = false
    
    private let imageId: String
    private let repository = ScreenshotRepository.shared
    
    // MARK: - Init
    init(imageId: String) {
        self.imageId = imageId
    }
    
    // MARK: - Computed Properties
    var displayImage: UIImage {
        item?.fullImage ?? UIImage(resource: .apple)
    }
    
    @Published var tags: [String] = []
    
    // MARK: - Setup Methods
    private func setupInitialTags() {
        guard let item = item else { return }
        tags = item.tags.map { $0.name }
        tempSelectedTags = Set(tags)
    }
    
    func onAppear() {
        Task {
            await loadItemData()
        }
    }
    
    /// imageId로 아이템 데이터 로드
    private func loadItemData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let loadedItem = try await repository.fetchItem(by: imageId)
            guard let loadedItem = loadedItem else {
                errorMessage = "해당 이미지를 찾을 수 없습니다."
                return
            }
            
            self.item = loadedItem
            self.isFavorite = loadedItem.isFavorite // 즐겨찾기 상태 동기화
            setupInitialTags()
            
            // 풀 이미지 로드
            await loadedItem.loadFullImage()
            
        } catch {
            errorMessage = "이미지 로드 중 오류가 발생했습니다: \(error.localizedDescription)"
            debugPrint("❌ 아이템 로드 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Tag Management
    func showAddTagSheet() {
        isShowingAddTagSheet = true
    }
    
    func hideAddTagSheet() {
        isShowingAddTagSheet = false
    }
    
    func addNewTag(_ newTag: String) {
        guard let item = item else { return }
        
        // 빈 문자열이나 이미 존재하는 태그는 추가하지 않음
        guard !newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
              /*!item.tags.contains(newTag)*/ else { return }
        
        // 최대 4개 태그 제한
        guard item.tags.count < 4 else {
            debugPrint("⚠️ 태그는 최대 4개까지만 추가할 수 있습니다.")
            return
        }
        
        // 새 태그 추가
        item.addTag(newTag)
        tags.append(newTag)  // UI 업데이트를 위해 @Published tags 배열에도 추가
        tempSelectedTags.insert(newTag)
        
        debugPrint("✅ 새 태그 추가됨: \(newTag)")
        
        saveTags(newTag)
    }
    
    func deleteTag(_ tag: String) {
        guard let item = item else { return }
        var tagIndex: Int = 0
        let tagNames = item.tags.map { $0.name }
        if AccountStorage.shared.isGuest ?? true {
            tagIndex = tagNames.firstIndex(of: tag) ?? 0
        } else if let tagId = item.tags.first(where: {$0.name == tag}) {
            tagIndex = tagId.id
        }
        
        // UI 상태 업데이트
        item.removeTag(tag)
        tags.removeAll { $0 == tag }
        tempSelectedTags.remove(tag)
        
        // 서버에 삭제 요청
        Task {
            do {
                try await ScreenshotRepository.shared.deleteTag(imageId: item.id, tagId: String(tagIndex))
                debugPrint("✅ 태그 삭제 완료: \(tag)")
                
                // 다른 뷰들에게 태그 변경 알림
                NotificationCenter.default.post(
                    name: NSNotification.Name("TagChanged"),
                    object: nil,
                    userInfo: ["imageId": item.id, "action": "delete", "tag": tag]
                )
            } catch {
                debugPrint("❌ 태그 삭제 실패: \(error.localizedDescription)")
                
                // 실패 시 UI 상태 복원
                item.addTag(tag)
                tags.append(tag)
                tempSelectedTags.insert(tag)
            }
        }
    }
    
    func saveTags(_ newTag: String) {
        guard let item = item else { return }
        Task {
            do {
                let result = try await ScreenshotRepository.shared.updateTag(id: item.id, tags: [newTag])
                
                switch result {
                case .success(let data):
                    item.tags += data.data
                case .failure(let error):
                    print("❌ 태그 추가 실패: \(error)")
                case .none:
                    print("💬 로컬: NO Tag ID")
                }
                debugPrint("✅ 태그 추가 완료: \(newTag)")
                
                // 다른 뷰들에게 태그 변경 알림
                NotificationCenter.default.post(
                    name: NSNotification.Name("TagChanged"),
                    object: nil,
                    userInfo: ["imageId": item.id, "action": "add", "tag": newTag]
                )
            } catch {
                debugPrint("❌ 태그 추가 실패: \(error.localizedDescription)")
                print(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Delete Management
    func showDeleteConfirmation() {
        withAnimation {
            isDeleted = true
        }
    }
    
    func hideDeleteConfirmation() {
        isDeleted = false
    }
    
    func deleteScreenshot() async {
        guard let item = item else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await item.delete()
            debugPrint("✅ 스크린샷 삭제 완료: \(item.fileName)")
            
            // 다른 뷰들에게 스크린샷 삭제 알림
            NotificationCenter.default.post(
                name: NSNotification.Name("ScreenshotDeleted"),
                object: nil,
                userInfo: ["imageId": item.id]
            )
        } catch {
            errorMessage = "삭제 중 오류가 발생했습니다: \(error.localizedDescription)"
            debugPrint("❌ 스크린샷 삭제 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Favorite Management
    func toggleFavorite() {
        guard let item = item else { return }
        
        // 1. UI 상태 즉시 업데이트 (낙관적 업데이트)
        let originalState = item.isFavorite
        item.isFavorite.toggle()
        isFavorite.toggle() // DetailView의 UI 즉시 업데이트
        
        Task {
            do {
                if originalState {
                    // 원래 즐겨찾기 상태였으면 삭제
                    try await ScreenshotRepository.shared.deleteFavorite(id: item.id)
                    debugPrint("✅ 즐겨찾기 제거 완료: \(item.fileName)")
                } else {
                    // 원래 즐겨찾기가 아니었으면 추가
                    try await ScreenshotRepository.shared.uploadFavorite(id: item.id)
                    debugPrint("✅ 즐겨찾기 추가 완료: \(item.fileName)")
                }
                
                // 3. 성공 시 다른 뷰들에게 상태 변경 알림
                let favoriteInfo = FavoriteStatusInfo(imageId: item.id, isFavorite: item.isFavorite)
                NotificationCenter.default.post(
                    name: .favoriteStatusChanged,
                    object: nil,
                    userInfo: ["favoriteInfo": favoriteInfo]
                )
                
            } catch {
                // 2. 실패 시 UI 상태 원복
                item.isFavorite = originalState
                isFavorite = originalState // DetailView의 UI도 원복
                errorMessage = "즐겨찾기 변경 중 오류가 발생했습니다: \(error.localizedDescription)"
                debugPrint("❌ 즐겨찾기 토글 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
}
