//
//  ScreenshotDataManager.swift
//  CaptureCat
//
//  Created by minsong kim on 7/14/25.
//

import SwiftUI
import Photos
import Combine
import SwiftData

// ScreenshotManager와 SwiftData를 연동하는 매니저
final class ScreenshotDataManager: ObservableObject {
    @Published var screenshots: [ScreenshotWithAsset] = []
    @Published var isLoading: Bool = false
    
    private let screenshotManager = ScreenshotManager()
    private let swiftDataManager = SwiftDataManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
        loadScreenshots()
    }
    
    private func setupBindings() {
        // ScreenshotManager의 assets 변화를 감지
        screenshotManager.$assets
            .receive(on: DispatchQueue.main)
            .sink { [weak self] assets in
                self?.syncWithCoreData(assets: assets)
            }
            .store(in: &cancellables)
    }
    
    private func loadScreenshots() {
        isLoading = true
        
        // SwiftData에서 저장된 Screenshot과 PHAsset을 매칭
        let savedScreenshots = swiftDataManager.fetchAllScreenshots()
        let assets = screenshotManager.assets
        
        screenshots = assets.compactMap { asset in
            let savedScreenshot = savedScreenshots.first { $0.fileName == asset.localIdentifier }
            return ScreenshotWithAsset(asset: asset, screenshot: savedScreenshot)
        }
        
        isLoading = false
    }
    
    private func syncWithCoreData(assets: [PHAsset], isFavorite: Bool = false) {
        // 새로운 assets이 있으면 SwiftData에 저장
        assets.forEach { asset in
            if swiftDataManager.fetchScreenshot(with: asset.localIdentifier) == nil {
                swiftDataManager.saveScreenshot(from: asset, isFavorite: isFavorite)
            }
        }
        
        loadScreenshots()
    }
    
    // MARK: - Public Methods
    
    /// 특정 태그로 필터링된 스크린샷 조회
    func getScreenshots(with tag: String) -> [ScreenshotWithAsset] {
        let filteredScreenshots = swiftDataManager.fetchScreenshots(with: tag)
        let filteredIds = Set(filteredScreenshots.map { $0.fileName })
        
        return screenshots.filter { screenshotWithAsset in
            filteredIds.contains(screenshotWithAsset.asset.localIdentifier)
        }
    }
    
    /// 태그가 없는 스크린샷 조회
    func getUntaggedScreenshots() -> [ScreenshotWithAsset] {
        return screenshots.filter { screenshotWithAsset in
            guard let screenshot = screenshotWithAsset.screenshot else { return true }
            return screenshot.tags.isEmpty
        }
    }
    
    /// 즐겨찾기 스크린샷 조회
    func getFavoriteScreenshots() -> [ScreenshotWithAsset] {
        return screenshots.filter { $0.asset.isFavorite }
    }
    
    /// 모든 사용된 태그 조회
    func getAllUsedTags() -> [String] {
        return swiftDataManager.fetchAllUsedTags()
    }
}

/// PHAsset과 Screenshot Entity를 함께 담는 구조체
struct ScreenshotWithAsset: Identifiable {
    let id: String
    let asset: PHAsset
    let screenshot: Screenshot?
    
    init(asset: PHAsset, screenshot: Screenshot? = nil) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.screenshot = screenshot
    }
    
    var tags: [String] {
        return screenshot?.tags ?? []
    }
    
    var hasTag: Bool {
        return !tags.isEmpty
    }
} 
