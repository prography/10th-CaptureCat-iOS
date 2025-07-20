//
//  TagViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import SwiftUI
import Photos

@MainActor
/// 한 번에(Batch) 혹은 한 장씩(Single) 모드에서 태그 편집을 담당하는 ViewModel
final class TagViewModel: ObservableObject {
    enum Mode: Int {
        case batch = 0    // 한 번에
        case single = 1   // 한 장씩
    }
    
    // MARK: - Published Properties
    @Published var hasChanges: Bool = false
    @Published var mode: Mode = .batch
    @Published var isShowingAddTagSheet: Bool = false
    let segments = ["한번에", "한장씩"]
    
    @Published var tags: [String] = []
    @Published var selectedTags: Set<String> = []

    @Published var currentIndex: Int = 0
    
    // MARK: - Dependencies
    private let repository = ScreenshotRepository.shared
    var itemVMs: [ScreenshotItemViewModel] = []
    
    // MARK: - Init
    /// PHAsset 배열을 받아서 대응하는 ScreenshotItemViewModel들을 준비
    init(itemsIds: [String]) {
        self.itemVMs = repository.fetchViewModels(for: itemsIds)
        
        loadTags()
        updateSelectedTags()
    }
    
    // MARK: - Computed for UI
    /// 현재 화면에 표시할 ViewModel (batch: 첫 번째, single: currentIndex)
    var displayVM: ScreenshotItemViewModel? {
        switch mode {
        case .batch:
            return itemVMs.first
        case .single:
            guard currentIndex < itemVMs.count else { return nil }
            return itemVMs[currentIndex]
        }
    }
    
    /// 진행률 텍스트 ("1/5" 등)
    var progressText: String {
        guard !itemVMs.isEmpty else { return "0/0" }
        let idx = min(currentIndex, itemVMs.count - 1)
        return "\(idx + 1)/\(itemVMs.count)"
    }
    
    // MARK: - Tag Loading
    /// 전체 태그 목록을 로컬/서버에서 가져와 tags에 세팅
    func loadTags() {
        do {
            tags = try repository.fetchAllTags()
        } catch {
            print("🐞 태그 목록 가져와서 저장 중 에러: ", error.localizedDescription)
        }
    }
    
    /// mode 변경이나 asset 변경 시 호출해서 selectedTags 초기화
    private func updateSelectedTags() {
        switch mode {
        case .batch:
            // 모든 아이템의 공통 태그(교집합)
            let sets = itemVMs.map { Set($0.tags) }
            if let first = sets.first {
                selectedTags = sets.dropFirst().reduce(first) { $0.intersection($1) }
            } else {
                selectedTags = []
            }
        case .single:
            selectedTags = Set(displayVM?.tags ?? [])
        }
    }
    
    // MARK: - Mode & Navigation
    /// 세그먼트 모드 변경 시 호출
    func onModeChanged() {
        if mode == .batch {
            mode = .single
        } else {
            mode = .batch
        }
//        currentIndex = 0
        updateSelectedTags()
        hasChanges = false
    }
    
    /// Carousel 등에서 index 변경 시 호출
    func onAssetChanged(to index: Int) {
        currentIndex = index
        updateSelectedTags()
        hasChanges = false
    }
    
    // MARK: - User Actions
    
    func addTagButtonTapped() {
        withAnimation {
            self.isShowingAddTagSheet = true
        }
    }
    /// 태그 선택/해제
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else if selectedTags.count < 4 {
            selectedTags.insert(tag)
        }
        hasChanges = true
    }
    
    /// 새 태그 추가 (로컬+서버 동기화)
    func addNewTag(name: String) {
        guard !tags.contains(name) else { return }
        tags.append(name)
        Task {
            do {
                try await repository.addTag(name, toIDs: itemVMs.map { $0.id })
            } catch {
                // 에러 처리
            }
        }
    }
    
    /// 태그 이름 변경 (로컬+서버)
    func renameTag(from oldName: String, to newName: String) {
        guard let idx = tags.firstIndex(of: oldName) else { return }
        tags[idx] = newName
        Task {
            do {
                try await repository.renameTag(from: oldName, to: newName)
            } catch {
                // 에러 처리
            }
        }
        // 선택된 태그 업데이트
        if selectedTags.contains(oldName) {
            selectedTags.remove(oldName)
            selectedTags.insert(newName)
        }
    }
    
    /// 변경된 태그를 저장 (batch: all items, single: current)
    func save() {
        let newTags = Array(selectedTags)
        switch mode {
        case .batch:
            for vm in itemVMs {
                vm.tags = newTags
                Task { await vm.saveChanges() }
            }
        case .single:
            if let vm = displayVM {
                vm.tags = newTags
                Task { await vm.saveChanges() }
            }
        }
        hasChanges = false
    }
}
