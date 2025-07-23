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
    
    var tags: [String] {
        item.tags
    }
    
    // MARK: - Setup Methods
    private func setupInitialTags() {
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
    
    func updateTags(with newTags: [String]) {
        // 기존 태그 제거
        for existingTag in item.tags {
            if !newTags.contains(existingTag) {
                item.removeTag(existingTag)
            }
        }
        
        // 새 태그 추가
        for newTag in newTags {
            if !item.tags.contains(newTag) {
                item.addTag(newTag)
            }
        }
        
        tempSelectedTags = Set(newTags)
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
    
    // MARK: - Error Handling
    func clearError() {
        errorMessage = nil
    }
}
