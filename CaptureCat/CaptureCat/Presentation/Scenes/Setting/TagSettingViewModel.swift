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
    @Published var isDisabled: Bool = true               // 상단 "편집" 버튼 활성/비활성 제어(예시 용도)
    @Published var addTag: String = ""                // 검색/추가 입력값
    @Published var selectedTag: Tag? = nil               // 현재 편집 중인 태그
    @Published var isShowingEditSheet: Bool = false      // 편집 시트 표시 여부
    @Published var tags: [Tag] = []                      // 태그 목록
    
    // MARK: - Derived
    var tagCountText: String { "\(tags.count)/30" }
    
    var isEditButtonEnabled: Bool { !tags.isEmpty }
    
    // MARK: - Actions
    func registerTag() {
        let trimmed = addTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !tags.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) else { return }
        guard tags.count < 30 else { return }
        
        let newId = (tags.map { $0.id }.max() ?? 0) + 1
        tags.append(Tag(id: newId, name: trimmed))
        addTag = ""
        isDisabled = tags.isEmpty == false
    }
    
    func edit(_ tag: Tag) {
        selectedTag = tag
        isShowingEditSheet = true
    }
    
    func updateTag(_ updated: Tag) {
        guard let idx = tags.firstIndex(where: { $0.id == updated.id }) else { return }
        tags[idx] = updated
    }
    
    func removeTag(_ tag: Tag) {
        tags.removeAll { $0.id == tag.id }
        isDisabled = tags.isEmpty
    }
}
