//
//  TagViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import SwiftUI
import Photos

enum Mode: Int {
    case batch = 0    // 한 번에
    case single = 1   // 한 장씩
}

/// 한 번에(Batch) 혹은 한 장씩(Single) 모드에서 태그 편집을 담당하는 ViewModel
@MainActor
final class TagViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var hasChanges: Bool = false
    @Published var mode: Mode = .batch
    @Published var isShowingAddTagSheet: Bool = false
    @Published var pushNext: Bool = false
    let segments = ["한번에", "한장씩"]
    
    @Published var tags: [String] = []
    @Published var selectedTags: Set<String> = []
    var batchSelectedTags: Set<String> = []
    
    @Published var currentIndex: Int = 0
    
    // MARK: - Dependencies
    private let repository = ScreenshotRepository.shared
    @Published var itemVMs: [ScreenshotItemViewModel] = []
    private var networkManager: NetworkManager
    var router: Router?
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    /// UI 업데이트를 강제하기 위한 더미 프로퍼티 (Extension에서 사용)
    @Published var updateTrigger = false
    @Published var isUploading: Bool = false
    @Published var uploadProgress: Double = 0.0  // 업로드 진행률 (0.0 ~ 1.0)
    @Published var uploadedCount: Int = 0  // 업로드 완료된 아이템 수
    
    init(itemsIds: [String], networkManager: NetworkManager, router: Router? = nil) {
        self.networkManager = networkManager
        self.router = router
        createViewModel(from: itemsIds)
        
        loadTags()
        updateSelectedTags()
    }
    
    deinit {
        // 삭제 큐 정리
        pendingDeletions.removeAll()
        debugPrint("🧹 TagViewModel 해제 - 삭제 큐 정리 완료")
    }
    
    func checkHasChanges() {
        var result = 0
        for item in itemVMs {
            if item.tags.isEmpty {
                result += 1
            }
        }
        
        if result == 0 {
            hasChanges = true
        } else {
            hasChanges = false
        }
    }
    
    // 배열을 받아서 대응하는 ScreenshotItemViewModel들을 생성
    func createViewModel(from ids: [String]) {
        let results =  PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        results.enumerateObjects { asset, _, _ in
            let newItem = ScreenshotItem(
                id: asset.localIdentifier,
                imageData: Data(),
                fileName: asset.localIdentifier + ".jpg",
                createDate: self.dateFormatter.string(from: asset.creationDate ?? Date()),
                tags: [],
                isFavorite: asset.isFavorite
            )
            self.itemVMs.append( (ScreenshotItemViewModel(model: newItem)))
        }
    }
    
    // MARK: - Computed for UI
    /// 현재 화면에 표시할 ViewModel (batch: 첫 번째, single: currentIndex) - 안전한 접근
    var displayVM: ScreenshotItemViewModel? {
        switch mode {
        case .batch:
            return itemVMs.first
        case .single:
            // 완전한 인덱스 검증
            guard currentIndex >= 0 && currentIndex < itemVMs.count else {
                debugPrint("⚠️ displayVM: 잘못된 currentIndex \(currentIndex) (총 \(itemVMs.count)개)")
                return nil
            }
            return itemVMs[currentIndex]
        }
    }
    
    /// 진행률 텍스트 ("1/5" 등)
    var progressText: String {
        guard !itemVMs.isEmpty else { return "0/0" }
        let idx = min(currentIndex, itemVMs.count - 1)
        return "\(idx + 1)/\(itemVMs.count)"
    }
    
    // 태그 관리 메서드들은 TagViewModel+TagManagement.swift에 분리
    
    // MARK: - Extension Properties (Extension에서 사용하는 프로퍼티들)
    
    /// 삭제 작업 큐 시스템 프로퍼티들
    var pendingDeletions: [Int] = []
    var isProcessingDeletion = false
    
    /// 통합 상태 관리
    @Published var isDeletingItem = false  // UI 표시용
    @Published var deletionProgress: String = ""  // 삭제 진행률
    @Published var shouldSyncCarousel = false  // 캐러셀 동기화 트리거
}

// MARK: - Extension Files
// 기능별로 분리된 Extension 파일들:
// - TagViewModel+DeleteManagement.swift: 삭제 관리 관련 메서드들
// - TagViewModel+TagManagement.swift: 태그 관리 관련 메서드들  
// - TagViewModel+SaveOperations.swift: 저장 작업 관련 메서드들
