//
//  StartGetScreenshotViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 6/29/25.
//

import Combine
import SwiftUI
import Photos

final class StartGetScreenshotViewModel: ObservableObject {
    // MARK: Published state
    @Published var assets: [PHAsset] = []
    @Published var selectedIDs: Set<String> = []
    @Published var showOverlimitToast: Bool = false

    // MARK: Constants
    private let maxSelection = 10

    // MARK: Dependencies
    private let manager = ScreenshotManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init
    init() {
        // ① 최초 데이터 로드
        assets = manager.assets

        // ② ScreenshotManager가 변하면 뷰에도 반영
        manager.$assets
            .receive(on: DispatchQueue.main)
            .assign(to: &$assets)
    }

    // MARK: Computed
    var totalCount: Int { manager.totalCount }

    // MARK: User intent
    func toggleSelection(of asset: PHAsset) {
        let id = asset.localIdentifier

        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
            return
        }

        guard selectedIDs.count < maxSelection else {
            withAnimation { showOverlimitToast = true }
            return
        }

        selectedIDs.insert(id)
    }
    
    // 선택된 에셋들 반환
    func selectedAssets() -> [PHAsset] {
        return assets.filter { selectedIDs.contains($0.localIdentifier) }
    }
}
