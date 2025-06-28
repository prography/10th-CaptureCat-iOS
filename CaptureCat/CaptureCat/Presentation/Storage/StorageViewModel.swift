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
    @Published var showCountToast = false
    @Published var isAllSelected = false

    // MARK: - Constants
    private let maxSelection = 20

    // MARK: - Dependencies
    private let manager = ScreenshotManager()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init() {
        // 초기 데이터
        assets = manager.assets

        // ScreenshotManager → ViewModel 동기화
        manager.$assets
            .receive(on: DispatchQueue.main)
            .assign(to: &$assets)
    }

    // MARK: - Derived
    var totalCount: Int { manager.totalCount }

    // MARK: - User intent
    func toggleSelection(of asset: PHAsset) {
        let id = asset.localIdentifier

        // 이미 선택된 항목이면 해제
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
            if isAllSelected {
                isAllSelected = false
            } else {
                triggerCountToast()
            }
            return
        }
        
        // 최대 개수 초과 방지
        guard selectedIDs.count < maxSelection else {
            withAnimation { showOverlimitToast = true }
            return
        }

        selectedIDs.insert(id)
        triggerCountToast()
    }
    
    func toggleAllSelection() {
        if selectedIDs.isEmpty {
            selectAll()
        } else {
            deselectAll()
        }
        isAllSelected.toggle()
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

    // MARK: - Private
    private func triggerCountToast() {
        withAnimation { showCountToast = true }
    }
    
    private func selectAll() {
        manager.selectAll()
        selectedIDs = manager.selectedIDs
    }
    
    private func deselectAll() {
        manager.deselectAll()
        selectedIDs.removeAll()
    }
}
