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
    
    private let item: ScreenshotItemViewModel
    
    // MARK: - Init
    init(item: ScreenshotItemViewModel) {
        self.item = item
        setupInitialTags()
    }
    
    // MARK: - Computed Properties
    var formattedDate: String {
        item.createDate.toString(format: "yyyy년 MM월 dd일")
    }
    
    var displayImage: UIImage {
        item.fullImage ?? UIImage(resource: .apple)
    }
    
    @Published var tags: [String] = []
    
    // MARK: - Setup Methods
    private func setupInitialTags() {
        tags = item.tags
        tempSelectedTags = Set(item.tags)
    }
    
    func onAppear() {
        tempSelectedTags = Set(item.tags)
        Task {
            await loadFullImageIfNeeded()
        }
    }
    
    // MARK: - Image Loading
    private func loadFullImageIfNeeded() async {
        guard item.fullImage == nil else { return }
        
        isLoading = true
        await item.loadFullImage()
        isLoading = false
    }
    
    // MARK: - Tag Management
    func showAddTagSheet() {
        isShowingAddTagSheet = true
    }
    
    func hideAddTagSheet() {
        isShowingAddTagSheet = false
    }
    
    func addNewTag(_ newTag: String) {
        // 빈 문자열이나 이미 존재하는 태그는 추가하지 않음
        guard !newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !item.tags.contains(newTag) else { return }
        
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
        guard let tagIndex = item.tags.firstIndex(of: tag) else {
            debugPrint("⚠️ 삭제하려는 태그를 찾을 수 없음: \(tag)")
            return
        }
        
        // UI 상태 업데이트
        item.removeTag(tag)
        tags.removeAll { $0 == tag }
        tempSelectedTags.remove(tag)
        
        // 서버에 삭제 요청
        Task {
            do {
                try await ScreenshotRepository.shared.deleteTag(imageId: item.id, tagId: String(tagIndex + 1))
                debugPrint("✅ 태그 삭제 완료: \(tag)")
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
        Task {
            do {
                try await ScreenshotRepository.shared.updateTag(id: item.id, tags: [newTag])
            } catch {
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
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await item.delete()
            debugPrint("✅ 스크린샷 삭제 완료: \(item.fileName)")
        } catch {
            errorMessage = "삭제 중 오류가 발생했습니다: \(error.localizedDescription)"
            debugPrint("❌ 스크린샷 삭제 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Favorite Management
    func toggleFavorite() {
        // 1. UI 상태 즉시 업데이트 (낙관적 업데이트)
        let originalState = item.isFavorite
        item.isFavorite.toggle()
        
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
            } catch {
                // 2. 실패 시 UI 상태 원복
                item.isFavorite = originalState
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
