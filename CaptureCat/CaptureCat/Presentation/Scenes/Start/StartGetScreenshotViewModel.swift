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
    @Published var assets: [PHAsset] = []
    @Published var selectedIDs: Set<String> = []
    /// 선택 초과 시 토스트 표시 여부
    @Published var showOverlimitToast: Bool = false
    
    // MARK: - Constants
    private let maxSelection = 10
    
    // MARK: - Dependencies
    private let manager = ScreenshotManager()
    private var cancellables = Set<AnyCancellable>()
    private var service: TutorialService
    
    // MARK: - Init
    init(service: TutorialService) {
        self.service = service
        
        // 초기 데이터
        assets = manager.assets

        // ScreenshotManager → ViewModel 동기화
        manager.$assets
            .receive(on: DispatchQueue.main)
            .assign(to: &$assets)
    }
    
    // MARK: - Computed
    /// 전체 아이템 수
    var totalCount: Int { manager.totalCount }
    /// 선택된 아이템 ViewModel 배열
    
    func toggleSelection(of asset: PHAsset) {
        let id = asset.localIdentifier
        // 이미 선택된 항목이면 해제
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
            return
        }
        
        // 최대 개수 초과 방지
        guard selectedIDs.count < maxSelection else {
            triggerCountToast()
            return
        }
        
        selectedIDs.insert(id)
    }
    
    func tutorialCompleted() {
        Task {
            let result = await service.turorialComplete()
            
            switch result {
            case .success:
                debugPrint("✅ 튜토리얼 완료!")
            case .failure(let error):
                debugPrint("error: \(error)")
            }
        }
    }
    
    // MARK: - Private
    private func triggerCountToast() {
        withAnimation { showOverlimitToast = true }
    }
}
