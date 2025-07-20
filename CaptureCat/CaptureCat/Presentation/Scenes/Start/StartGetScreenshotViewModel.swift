//
//  StartGetScreenshotViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 6/29/25.
//

import Combine
import SwiftUI
import Photos

/// 스크린샷 선택 흐름을 위한 ViewModel
@MainActor
final class StartGetScreenshotViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var items: [ScreenshotItemViewModel] = []
    @Published var selectedIDs: Set<String> = []
    /// 선택 초과 시 토스트 표시 여부
    @Published var showOverlimitToast: Bool = false
    
    // MARK: - Constants
    private let maxSelection = 10
    
    // MARK: - Dependencies
    private let manager = ScreenshotManager()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init() {
        // 초기 데이터
        items = manager.itemVMs
        
        // ScreenshotManager → ViewModel 동기화
        manager.$itemVMs
            .receive(on: DispatchQueue.main)
            .assign(to: \.items, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Computed
    /// 전체 아이템 수
    var totalCount: Int { manager.totalCount }
    /// 선택된 아이템 ViewModel 배열
    
    func toggleSelection(of id: String) {
        // 이미 선택된 항목이면 해제
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
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
    
    // MARK: - Private
    private func triggerCountToast() {
        withAnimation { showOverlimitToast = true }
    }
}
