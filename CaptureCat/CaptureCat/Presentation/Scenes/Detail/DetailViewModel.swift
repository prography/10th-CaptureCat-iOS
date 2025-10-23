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
    @Published var showError: Bool = false
    @Published var item: ScreenshotItemViewModel?
    @Published var isFavorite: Bool = false
    
    private let imageId: String
    private let repository: ScreenshotRepository
    
    // MARK: - Init
    init(imageId: String, repository: ScreenshotRepository) {
        self.imageId = imageId
        self.repository = repository
    }
    
    // MARK: - Computed Properties
    var displayImage: UIImage {
        item?.fullImage ?? UIImage(resource: .apple)
    }
    
    @Published var tags: [String] = []
    
    // MARK: - Error Handling
    private func showError(_ message: String) {
        errorMessage = message
        showError = true
        
        // 3초 후 자동으로 에러 메시지 숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.clearError()
        }
    }
    
    private func clearError() {
        errorMessage = nil
        showError = false
    }
    
    private func getErrorMessage(from error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.tagErrorMessage
        }
        return error.localizedDescription
    }
    
    // MARK: - Setup Methods
    private func setupInitialTags() {
        guard let item = item else { return }
        tempSelectedTags = Set(item.tags.map { $0.name })
    }
    
    func loadTags() async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let loadedTags = try await repository.fetchAllUserTag()
            await MainActor.run {
                self.tags = loadedTags.map { $0.name }
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                print("태그 로딩 실패: \(error)")
                self.tags = []
                self.isLoading = false
            }
        }
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
            await loadTags()
            
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
    
    func registerTag(_ newTag: String) {
        Task {
            // 로그인 모드: 서버에 등록
            do {
                let result = try await repository.registerUserTag(name: newTag)
                switch result {
                case .success(let userTag):
                    await MainActor.run {
                        if !self.tags.contains(userTag.data.name) {
                            self.tags.append(userTag.data.name)
                        }
                    }
                case .failure(let error):
                    print("태그 등록 실패: \(error)")
                    await MainActor.run {
                        self.showError(self.getErrorMessage(from: error))
                    }
                }
            } catch {
                print("태그 등록 중 오류: \(error)")
                await MainActor.run {
                    self.showError(self.getErrorMessage(from: error))
                }
            }
        }
    }
    
    func addNewTag(_ newTag: String) {
        guard let item = item else { return }
        
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 클라이언트 측 검증
        guard !trimmed.isEmpty else {
            showError("태그 이름을 입력해주세요")
            return
        }
        
        guard trimmed.count <= 20 else {
            showError("태그 이름은 20자 이하로 입력해주세요")
            return
        }
        
        // 이미 선택된 태그인지 확인
        guard !tempSelectedTags.contains(trimmed) else {
            showError("이미 추가된 태그입니다")
            return
        }
        
        // 최대 4개 태그 제한
        guard item.tags.count < 4 else {
            showError("태그는 최대 4개까지 추가할 수 있습니다")
            return
        }
        
        // 에러 상태 초기화
        clearError()
        
        // 새 태그 추가
        registerTag(trimmed)
        item.addTag(trimmed)
        if !tags.contains(trimmed) {
            tags.append(trimmed)  // UI 업데이트를 위해 @Published tags 배열에도 추가
        }
        tempSelectedTags.insert(trimmed)
        
        debugPrint("✅ 새 태그 추가됨: \(trimmed)")
        
        saveTags(trimmed)
    }
    
    func addTagByChip(_ newTag: String) {
        guard let item = item else { return }
        
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 이미 선택된 태그인지 확인
        guard !tempSelectedTags.contains(trimmed) else {
            showError("이미 추가된 태그입니다")
            return
        }
        
        // 최대 4개 태그 제한
        guard item.tags.count < 4 else {
            showError("태그는 최대 4개까지 추가할 수 있습니다")
            return
        }
        
        // 에러 상태 초기화
        clearError()
        
        // 새 태그 추가
        item.addTag(trimmed)
        tempSelectedTags.insert(trimmed)
        
        debugPrint("✅ 새 태그 추가됨: \(trimmed)")
        
        saveTags(trimmed)
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
                try await repository.deleteTag(imageId: item.id, tagId: String(tagIndex))
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
                let result = try await repository.updateTag(id: item.id, tags: [newTag])
                
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
                    try await repository.deleteFavorite(id: item.id)
                    debugPrint("✅ 즐겨찾기 제거 완료: \(item.fileName)")
                } else {
                    // 원래 즐겨찾기가 아니었으면 추가
                    try await repository.uploadFavorite(id: item.id)
                    debugPrint("✅ 즐겨찾기 추가 완료: \(item.fileName)")
                }
                
            } catch {
                // 2. 실패 시 UI 상태 원복
                item.isFavorite = originalState
                isFavorite = originalState // DetailView의 UI도 원복
                errorMessage = "즐겨찾기 변경 중 오류가 발생했습니다: \(error.localizedDescription)"
                debugPrint("❌ 즐겨찾기 토글 실패: \(error.localizedDescription)")
            }
        }
    }
}
