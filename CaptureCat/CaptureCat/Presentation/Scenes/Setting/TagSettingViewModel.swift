//
//  TagSettingViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 8/22/25.
//

import Combine
import SwiftUI

class TagSettingViewModel: ObservableObject {
    // MARK: - Published States
    @Published var isDisabled: Bool = true // 상단 "편집" 버튼 활성/비활성 제어(예시 용도)
    @Published var addTag: String = ""  // 검색/추가 입력값
    @Published var selectedTag: Tag? = nil // 현재 편집 중인 태그
    @Published var isShowingEditSheet: Bool = false // 편집 시트 표시 여부
    @Published var tags: [Tag] = [] // 태그 목록
    @Published var isLoading: Bool = false // 로딩 상태
    @Published var selectedTagIds: Set<Int> = [] // 선택된 태그 ID들
    
    // MARK: - Error States
    @Published var errorMessage: String? = nil // 태그 추가 에러 메시지
    @Published var showError: Bool = false // 태그 추가 에러 표시 상태
    @Published var loadErrorMessage: String? = nil // 태그 로딩 에러 메시지
    @Published var showLoadError: Bool = false // 태그 로딩 에러 표시 상태
    
    // EditTagSheet 전용 에러 상태
    @Published var editErrorMessage: String? = nil // 태그 수정 에러 메시지
    @Published var showEditError: Bool = false // 태그 수정 에러 표시 상태
    
    // MARK: - Dependencies
    private let repository: ScreenshotRepository
    
    // MARK: - Initializer
    init(repository: ScreenshotRepository) {
        self.repository = repository
    }
    
    // MARK: - Derived
    var tagCountText: String { "\(tags.count)/30" }
    
    var isEditButtonEnabled: Bool { !tags.isEmpty }
    
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
    
    private func showLoadError(_ message: String) {
        loadErrorMessage = message
        showLoadError = true
        
        // 5초 후 자동으로 로딩 에러 메시지 숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.clearLoadError()
        }
    }
    
    private func clearLoadError() {
        loadErrorMessage = nil
        showLoadError = false
    }
    
    private func getErrorMessage(from error: Error) -> String {
        if let networkError = error as? NetworkError {
            return networkError.tagErrorMessage
        }
        return error.localizedDescription
    }
    
    // MARK: - Edit Error Handling
    private func showEditError(_ message: String) {
        editErrorMessage = message
        showEditError = true
        
        // 3초 후 자동으로 에러 메시지 숨김
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.clearEditError()
        }
    }
    
    private func clearEditError() {
        editErrorMessage = nil
        showEditError = false
    }
    
    // MARK: - Data Loading
    func loadTags() async {
        await MainActor.run {
            isLoading = true
            clearLoadError()
        }
        
        do {
            let loadedTags = try await repository.fetchAllUserTag()
            await MainActor.run {
                self.tags = loadedTags
                self.isDisabled = loadedTags.isEmpty
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                print("태그 로딩 실패: \(error)")
                self.tags = []
                self.isDisabled = true
                self.isLoading = false
                self.showLoadError(self.getErrorMessage(from: error))
            }
        }
    }
    
    // MARK: - Actions
    func registerTag() {
        let trimmed = addTag.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 클라이언트 측 검증
        guard !trimmed.isEmpty else { 
            showError("태그 이름을 입력해주세요")
            return 
        }
        
        guard !tags.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else { 
            showError("이미 존재하는 태그입니다")
            return 
        }
        
        guard tags.count < 30 else { 
            showError("태그는 최대 30개까지 생성할 수 있습니다")
            return 
        }
        
        guard trimmed.count <= 20 else {
            showError("태그 이름은 20자 이하로 입력해주세요")
            return
        }
        
        // 에러 상태 초기화
        clearError()
        
        Task {
            if AccountStorage.shared.isGuest ?? true {
                // 게스트 모드: 로컬에만 추가
                let newId = (tags.map { $0.id }.max() ?? 0) + 1
                await MainActor.run {
                    tags.append(Tag(id: newId, name: trimmed))
                    addTag = ""
                    isDisabled = tags.isEmpty == false
                }
            } else {
                // 로그인 모드: 서버에 등록
                do {
                    let result = try await repository.registerUserTag(name: trimmed)
                    switch result {
                    case .success(let userTag):
                        await MainActor.run {
                            tags.append(userTag.data)
                            addTag = ""
                            isDisabled = tags.isEmpty == false
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
    }
    
    func edit(_ tag: Tag) {
        selectedTag = tag
        isShowingEditSheet = true
    }
    
    func updateTag(_ updated: Tag) {
        // 클라이언트 측 검증
        let trimmed = updated.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            showEditError("태그 이름을 입력해주세요")
            return
        }
        
        guard trimmed.count <= 20 else {
            showEditError("태그 이름은 20자 이하로 입력해주세요")
            return
        }
        
        guard !tags.contains(where: { $0.id != updated.id && $0.name.lowercased() == trimmed.lowercased() }) else {
            showEditError("이미 존재하는 태그입니다")
            return
        }
        
        clearEditError()
        
        if AccountStorage.shared.isGuest ?? true {
            // 게스트 모드: 로컬에서만 업데이트
            guard let idx = tags.firstIndex(where: { $0.id == updated.id }) else { return }
            tags[idx] = Tag(id: updated.id, name: trimmed)
            isShowingEditSheet = false
        } else {
            // 로그인 모드: 서버에 업데이트
            Task {
                do {
                    let result = try await repository.updateUserTag(tag: Tag(id: updated.id, name: trimmed))
                    switch result {
                    case .success(let userTag):
                        await MainActor.run {
                            guard let idx = tags.firstIndex(where: { $0.id == updated.id }) else { return }
                            tags[idx] = userTag.data
                            isShowingEditSheet = false
                        }
                    case .failure(let error):
                        print("태그 업데이트 실패: \(error)")
                        await MainActor.run {
                            self.showEditError(self.getErrorMessage(from: error))
                        }
                    }
                } catch {
                    print("태그 업데이트 중 오류: \(error)")
                    await MainActor.run {
                        self.showEditError(self.getErrorMessage(from: error))
                    }
                }
            }
        }
    }
    
    func removeTag(_ tag: Tag) {
        if AccountStorage.shared.isGuest ?? true {
            // 게스트 모드: 로컬에서만 삭제
            tags.removeAll { $0.id == tag.id }
            isDisabled = tags.isEmpty
        } else {
            // 로그인 모드: 서버에서 삭제
            Task {
                do {
                    let result = try await repository.deleteUserTag(id: tag.id)
                    switch result {
                    case .success:
                        await MainActor.run {
                            tags.removeAll { $0.id == tag.id }
                            isDisabled = tags.isEmpty
                        }
                    case .failure(let error):
                        print("태그 삭제 실패: \(error)")
                    }
                } catch {
                    print("태그 삭제 중 오류: \(error)")
                }
            }
        }
    }
    
    // MARK: - Tag Selection Management
    func toggleSelection(for tag: Tag) {
        if selectedTagIds.contains(tag.id) {
            selectedTagIds.remove(tag.id)
        } else {
            selectedTagIds.insert(tag.id)
        }
    }
    
    func isSelected(_ tag: Tag) -> Bool {
        return selectedTagIds.contains(tag.id)
    }
    
    func deleteSelectedTags() {
        let tagsToDelete = tags.filter { selectedTagIds.contains($0.id) }
        
        for tag in tagsToDelete {
            removeTag(tag)
        }
        
        // 삭제 완료 후 선택 상태 초기화
        selectedTagIds.removeAll()
    }
    
    func selectAllTags() {
        selectedTagIds = Set(tags.map { $0.id })
    }
}
