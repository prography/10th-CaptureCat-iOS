//
//  TagViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import SwiftUI
import Photos
import SwiftData

final class TagViewModel: ObservableObject {
    @Published var hasChanges: Bool = false
    @Published var assets: [PHAsset]
    @Published var selectedIndex: Int = 0
    let segments = ["한번에", "한장씩"]
    @Published var tags: [String] = []
    @Published var selectedTags: Set<String> = []
    @Published var isShowingAddTagSheet: Bool = false
    @Published var currentAssetIndex: Int = 0
    
    // 각 asset별 태그 선택 상태를 저장 (한장씩 모드에서 사용)
    private var assetTagsMap: [String: Set<String>] = [:]

    private let swiftDataManager = SwiftDataManager.shared

    init(assets: [PHAsset]) {
        self.assets = assets
        loadTags()
        loadExistingTagsForAssets()
        
        // 각 asset의 초기 태그 상태를 맵에 로드
        assets.forEach { asset in
            if let screenshot = swiftDataManager.fetchScreenshot(with: asset.localIdentifier) {
                assetTagsMap[asset.localIdentifier] = Set(screenshot.tags)
            } else {
                assetTagsMap[asset.localIdentifier] = []
            }
        }
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
        
        // 한장씩 모드에서는 현재 asset의 태그 상태를 저장
        if selectedIndex == 1, currentAssetIndex < assets.count {
            let currentAsset = assets[currentAssetIndex]
            assetTagsMap[currentAsset.localIdentifier] = selectedTags
        }
        
        hasChanges = true
    }

    func addTagButtonTapped() {
        isShowingAddTagSheet = true
    }

    func addNewTag(name: String) {
        // 중복 태그 체크
        if !tags.contains(name) {
            tags.append(name)
        }
    }
    
    // 모드 변경 시 호출
    func onModeChanged() {
        switch selectedIndex {
        case 0: // 한번에 모드
            loadExistingTagsForAssets()
        case 1: // 한장씩 모드
            loadTagsForCurrentAsset()
        default:
            break
        }
    }
    
    // Carousel에서 asset 변경 시 호출
    func onAssetChanged(to index: Int) {
        // 이전 asset의 태그 상태 저장 (한장씩 모드에서만)
        if selectedIndex == 1, currentAssetIndex < assets.count {
            let previousAsset = assets[currentAssetIndex]
            assetTagsMap[previousAsset.localIdentifier] = selectedTags
        }
        
        currentAssetIndex = index
        
        if selectedIndex == 1 { // 한장씩 모드에서만
            loadTagsForCurrentAsset()
        }
    }

    func save() {
        switch selectedIndex {
        case 0: // 한번에
            let selectedTagsArray = Array(selectedTags)
            assets.forEach { asset in
                swiftDataManager.replaceTags(selectedTagsArray, isFavorite: false, for: asset)
            }
        case 1: // 한장씩
            // 현재 asset의 태그 상태를 맵에 저장
            if currentAssetIndex < assets.count {
                let currentAsset = assets[currentAssetIndex]
                assetTagsMap[currentAsset.localIdentifier] = selectedTags
            }
            
            // 모든 asset의 변경사항을 저장
            assets.forEach { asset in
                if let tagsForAsset = assetTagsMap[asset.localIdentifier] {
                    let tagsArray = Array(tagsForAsset)
                    swiftDataManager.replaceTags(tagsArray, isFavorite: false, for: asset)
                }
            }
            
            // 맵 초기화
            assetTagsMap.removeAll()
        default:
            break
        }
        
        hasChanges = false
    }
    
    // 다음 asset으로 이동 (한장씩 모드에서 사용)
    func moveToNextAsset() {
        if currentAssetIndex < assets.count - 1 {
            currentAssetIndex += 1
            loadExistingTagsForCurrentAsset()
        }
    }
    
    // 이전 asset으로 이동 (한장씩 모드에서 사용)
    func moveToPreviousAsset() {
        if currentAssetIndex > 0 {
            currentAssetIndex -= 1
            loadExistingTagsForCurrentAsset()
        }
    }
    
    // 현재 asset 정보
    var currentAsset: PHAsset? {
        guard currentAssetIndex < assets.count else { return nil }
        return assets[currentAssetIndex]
    }
    
    // 진행률
    var progress: String {
        return "\(currentAssetIndex + 1)/\(assets.count)"
    }
    
    // 표시할 Asset (모드에 따라 다름)
    var displayAsset: PHAsset? {
        guard !assets.isEmpty else { return nil }
        
        switch selectedIndex {
        case 0: // 한번에 - 첫 번째 asset 표시
            return assets.first
        case 1: // 한장씩 - 현재 asset 표시
            return currentAsset
        default:
            return assets.first
        }
    }
    
    // MARK: - Private Methods
    private func loadTags() {
        // 기존에 사용된 태그들을 가져오기
        var allTags = swiftDataManager.fetchAllUsedTags()
        
        // 기본 태그가 없으면 추가
        let defaultTags = ["쇼핑", "여행", "레퍼런스", "코디", "맛집"]
        defaultTags.forEach { tagName in
            if !allTags.contains(tagName) {
                allTags.append(tagName)
            }
        }
        
        tags = allTags.sorted()
    }
    
    private func loadExistingTagsForAssets() {
        // 현재 assets에 이미 연결된 태그들을 selectedTags에 추가
        var commonTags: Set<String>?
        
        assets.forEach { asset in
            if let screenshot = swiftDataManager.fetchScreenshot(with: asset.localIdentifier) {
                let tagSet = Set(screenshot.tags)
                
                if commonTags == nil {
                    commonTags = tagSet
                } else {
                    commonTags = commonTags!.intersection(tagSet)
                }
            } else {
                // 태그가 없는 스크린샷이 있으면 공통 태그는 없음
                commonTags = []
            }
        }
        
        selectedTags = commonTags ?? []
    }
    
    // 현재 asset의 태그 로드 (한장씩 모드에서 사용)
    private func loadExistingTagsForCurrentAsset() {
        guard currentAssetIndex < assets.count else { return }
        
        let currentAsset = assets[currentAssetIndex]
        if let screenshot = swiftDataManager.fetchScreenshot(with: currentAsset.localIdentifier) {
            selectedTags = Set(screenshot.tags)
        } else {
            selectedTags = []
        }
    }
    
    // 현재 asset의 태그 로드 (임시 선택 상태 또는 저장된 상태)
    private func loadTagsForCurrentAsset() {
        guard currentAssetIndex < assets.count else { return }
        
        let currentAsset = assets[currentAssetIndex]
        
        // 먼저 임시로 선택된 태그가 있는지 확인
        if let tempTags = assetTagsMap[currentAsset.localIdentifier] {
            selectedTags = tempTags
        } else {
            // 없으면 SwiftData에서 저장된 태그 로드
            if let screenshot = swiftDataManager.fetchScreenshot(with: currentAsset.localIdentifier) {
                selectedTags = Set(screenshot.tags)
            } else {
                selectedTags = []
            }
            // 초기 상태를 맵에 저장
            assetTagsMap[currentAsset.localIdentifier] = selectedTags
        }
    }
}
