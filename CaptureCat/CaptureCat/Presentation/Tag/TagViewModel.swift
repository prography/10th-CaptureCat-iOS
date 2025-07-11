//
//  TagViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import SwiftUI
import Photos

final class TagViewModel: ObservableObject {
    @Published var hasChanges: Bool = false
    @Published var assets: [PHAsset]
    @Published var selectedIndex: Int = 0
    let segments = ["한번에", "한장씩"]
    @Published var tags: [String] = ["쇼핑", "여행", "레퍼런스", "4번", "5번"]
    @Published var selectedTags: Set<String> = []
    @Published var isShowingAddTagSheet: Bool = false

    init(assets: [PHAsset]) {
        self.assets = assets
    }

    var displayTags: [String] {
        let selectedList = tags.filter { selectedTags.contains($0) }
        let unselectedList = tags.filter { !selectedTags.contains($0) }
        return selectedList + unselectedList
    }

    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else if selectedTags.count < 4 {
            selectedTags.insert(tag)
        }
        hasChanges = true
    }

    func addTagButtonTapped() {
        isShowingAddTagSheet = true
    }

    func save() {
        // 저장 로직 구현
        // 예: 서버 전송 또는 로컬 저장 후 hasChanges 초기화
    }
}
