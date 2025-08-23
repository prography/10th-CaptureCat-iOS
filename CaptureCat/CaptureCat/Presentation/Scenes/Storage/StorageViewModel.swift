//
//  StorageViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 6/29/25.
//

import SwiftUI
import Photos
import Combine

final class StorageViewModel: ObservableObject {
    // MARK: - Published state
    @Published var assets: [PHAsset] = []
    @Published var selectedIDs: Set<String> = []
    @Published var showDeleteFailurePopup = false
    @Published var askDeletePopUp = false
    @Published var showOverlimitToast = false
    @Published var isAllSelected = false
    @Published var showPermissionAlert = false
    
    // MARK: - Constants
    private let maxSelection = 20
    
    // MARK: - Dependencies
    private let manager: ScreenshotManager
    private var cancellables = Set<AnyCancellable>()
    private var networkManager: NetworkManager
    
    // MARK: - Init
    init(networkManager: NetworkManager, repository: ScreenshotRepository) {
        self.networkManager = networkManager
        self.manager = ScreenshotManager(repository: repository)
        // 초기 데이터
        assets = manager.assets
        
        // ScreenshotManager → ViewModel 동기화
        manager.$assets
            .receive(on: DispatchQueue.main)
            .assign(to: &$assets)
    }
    
    // MARK: - Derived
    var totalCount: Int { manager.totalCount }
    var loadedCount: Int { manager.loadedCount }
    var isLoadingMore: Bool { manager.isLoadingMore }
    var hasMoreAssets: Bool { manager.hasMoreAssets }
    
    // MARK: - Pagination
    func loadNextPage() {
        manager.loadNextPage()
    }
    
    func shouldLoadMore(for asset: PHAsset) -> Bool {
        // 현재 asset이 끝에서 5번째 전이면 다음 페이지 로드
        guard let index = assets.firstIndex(of: asset) else { return false }
        return index >= assets.count - 5 && hasMoreAssets && !isLoadingMore
    }
    
    // MARK: - User intent
    func toggleSelection(of asset: PHAsset) {
        let id = asset.localIdentifier
        // 이미 선택된 항목이면 해제
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
            if isAllSelected {
                isAllSelected = false
            }
            return
        }
        
        // 최대 개수 초과 방지
        guard selectedIDs.count < maxSelection else {
            withAnimation { showOverlimitToast = true }
            return
        }
        
        selectedIDs.insert(id)
    }
    
    func toggleAllSelection() {
        if selectedIDs.isEmpty {
            selectAll()
            isAllSelected = true
        } else {
            deselectAll()
            isAllSelected = false
        }
    }
    
    func showDeletePopUp() {
        if selectedIDs.isEmpty {
            withAnimation {
                showDeleteFailurePopup = true
            }
        } else {
            withAnimation {
                askDeletePopUp = true
            }
        }
    }
    
    // 선택된 자산 삭제
    func deleteSelected() {
        // 선택된 ID에 해당하는 PHAsset만 골라서 삭제
        let toDelete = manager.assets.filter {
            selectedIDs.contains($0.localIdentifier)
        }
        guard toDelete.isEmpty == false else {
            return
        }
        manager.delete(assets: toDelete)
    }
    
    func selectedAssets() -> [PHAsset] {
        let selectedAssets = manager.assets.filter {
            selectedIDs.contains($0.localIdentifier)
        }
        
        return selectedAssets
    }
    
    // MARK: - Private
    private func selectAll() {
        manager.selectAll()
        selectedIDs = manager.selectedIDs
    }
    
    private func deselectAll() {
        manager.deselectAll()
        selectedIDs.removeAll()
    }
}

extension StorageViewModel {
    func checkPhotoPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .notDetermined:
            // 최초 요청
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                if newStatus == .denied || newStatus == .restricted {
                    DispatchQueue.main.async {
                        self.showPermissionAlert = true
                    }
                }
                // authorized/limited 이면 viewModel.assets 로직 실행됨
            }
        case .denied, .restricted:
            // 이미 거부된 상태
            showPermissionAlert = true
        case .authorized, .limited:
            // 접근 OK
            break
        @unknown default:
            break
        }
    }
    
    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
