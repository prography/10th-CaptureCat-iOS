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
    
    // MARK: - Dependencies
    private let repository: ScreenshotRepository
    
    // MARK: - Initializer
    init(repository: ScreenshotRepository) {
        self.repository = repository
    }
    
    // MARK: - Derived
    var tagCountText: String { "\(tags.count)/30" }
    
    var isEditButtonEnabled: Bool { !tags.isEmpty }
    
    // MARK: - Data Loading
    func loadTags() async {
        await MainActor.run {
            isLoading = true
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
            }
        }
    }
    
    // MARK: - Actions
    func registerTag() {
        let trimmed = addTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !tags.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else { return }
        guard tags.count < 30 else { return }
        
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
                            addTag = ""
                        }
                    }
                } catch {
                    print("태그 등록 중 오류: \(error)")
                    await MainActor.run {
                        addTag = ""
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
        if AccountStorage.shared.isGuest ?? true {
            // 게스트 모드: 로컬에서만 업데이트
            guard let idx = tags.firstIndex(where: { $0.id == updated.id }) else { return }
            tags[idx] = updated
        } else {
            // 로그인 모드: 서버에 업데이트
            Task {
                do {
                    let result = try await repository.updateUserTag(tag: updated)
                    switch result {
                    case .success(let userTag):
                        await MainActor.run {
                            guard let idx = tags.firstIndex(where: { $0.id == updated.id }) else { return }
                            tags[idx] = userTag.data
                        }
                    case .failure(let error):
                        print("태그 업데이트 실패: \(error)")
                    }
                } catch {
                    print("태그 업데이트 중 오류: \(error)")
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
