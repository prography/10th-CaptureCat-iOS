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
    var batchSelectedTags: Set<String> = []
    
    @Published var currentIndex: Int = 0
    
    // MARK: - Dependencies
    private let repository = ScreenshotRepository.shared
    @Published var itemVMs: [ScreenshotItemViewModel] = []
    private var networkManager: NetworkManager
    
    init(itemsIds: [String], networkManager: NetworkManager) {
        self.networkManager = networkManager
        createViewModel(from: itemsIds)
        
        loadTags()
        updateSelectedTags()
    }
    
    // 배열을 받아서 대응하는 ScreenshotItemViewModel들을 생성
    func createViewModel(from ids: [String]) {
        let results =  PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        results.enumerateObjects { asset, _, _ in
            let newItem = ScreenshotItem(
                id: asset.localIdentifier,
                imageData: Data(),
                fileName: asset.localIdentifier + ".jpg",
                createDate: asset.creationDate ?? Date(),
                tags: [],
                isFavorite: false
            )
            self.itemVMs.append( (ScreenshotItemViewModel(model: newItem)))
        }
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
        tags = UserDefaults.standard.stringArray(forKey: LocalUserKeys.selectedTopics.rawValue) ?? []
    }
    
    // mode 변경이나 asset 변경 시 호출해서 selectedTags 초기화
    func updateSelectedTags() {
        switch mode {
        case .batch:
            selectedTags = batchSelectedTags
        case .single:
            selectedTags = Set(itemVMs[currentIndex].tags)
        }
        hasChanges = true
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
    }
    
    // Carousel 등에서 index 변경 시 호출
    func onAssetChanged(to index: Int) {
        currentIndex = index
        updateSelectedTags()
    }
    
    // MARK: - User Actions
    func addTagButtonTapped() {
        withAnimation {
            self.isShowingAddTagSheet = true
        }
    }
    // 태그 선택/해제
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            switch mode {
            case .batch:
                batchSelectedTags.remove(tag)
                itemVMs.forEach { $0.removeTag(tag) }
            case .single:
                itemVMs[currentIndex].removeTag(tag)
            }
            selectedTags.remove(tag)
        } else if selectedTags.count < 4 {
            switch mode {
            case .batch:
                itemVMs.forEach { $0.addTag(tag) }
                batchSelectedTags.insert(tag)
            case .single:
                itemVMs[currentIndex].addTag(tag)
            }
            selectedTags.insert(tag)
        }
        hasChanges = true
        updateSelectedTags()
    }
    
    // 새 태그 추가
    func addNewTag(name: String) {
        guard !tags.contains(name) else { return }
        tags.append(name)
        itemVMs[currentIndex].addTag(name)
        updateSelectedTags()
    }
    
    // 저장 (batch: all items, single: current)
    func save() async {
        switch mode {
        case .batch:
            for viewModel in itemVMs {
                await viewModel.saveChanges()
            }
        case .single:
            if let viewModel = displayVM {
                await viewModel.saveChanges()
            }
        }
    }
}
