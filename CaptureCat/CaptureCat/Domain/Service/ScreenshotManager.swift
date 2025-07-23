//
//  ScreenshotManager.swift
//  CaptureCat
//
//  Created by minsong kim on 7/20/25.
//

import SwiftUI
import Photos
import Combine

struct ScreenshotGroup: Identifiable {
    let id: Date
    var assets: [PHAsset]
}

// Photos 라이브러리에서 "스크린샷"만 가져와 관리하고, 선택·삭제 등의 로직을 처리하는 매니저
final class ScreenshotManager: ObservableObject {
    @Published private(set) var assets: [PHAsset] = []
    @Published private(set) var itemVMs: [ScreenshotItemViewModel] = []
    @Published var selectedIDs: Set<String> = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isLoadingMore: Bool = false
    @Published private(set) var hasMoreAssets: Bool = true
    
    private var allAssets: PHFetchResult<PHAsset>?
    private var currentIndex: Int = 0
    private let pageSize: Int = 20
    private var cancellables = Set<AnyCancellable>()
    
    // 전체 스크린샷 개수
    var totalCount: Int {
        allAssets?.count ?? 0
    }
    
    // 현재 로드된 스크린샷 개수
    var loadedCount: Int {
        assets.count
    }
    
    init() {
        requestPermissionAndFetch()
    }
    
    // 사진 라이브러리 접근 권한 요청 후 페칭
    private func requestPermissionAndFetch() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard let self = self, status == .authorized else { return }
            DispatchQueue.main.async {
                self.fetchInitialScreenshots()
            }
        }
    }
    
    // 초기 스크린샷 로드 (첫 페이지)
    private func fetchInitialScreenshots() {
        isLoading = true
        currentIndex = 0
        assets = []
        itemVMs = []
        
        let options = PHFetchOptions()
        // 스크린샷 미디어 서브타입 필터
        options.predicate = NSPredicate(
            format: "mediaSubtype & %d != 0",
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        allAssets = PHAsset.fetchAssets(with: .image, options: options)
        hasMoreAssets = (allAssets?.count ?? 0) > 0
        
        loadNextPage()
        isLoading = false
    }
    
    // 다음 페이지 로드
    func loadNextPage() {
        guard let allAssets = allAssets,
              !isLoadingMore,
              hasMoreAssets,
              currentIndex < allAssets.count else {
            return
        }
        
        isLoadingMore = true
        
        let endIndex = min(currentIndex + pageSize, allAssets.count)
        var newAssets: [PHAsset] = []
        
        for i in currentIndex..<endIndex {
            newAssets.append(allAssets.object(at: i))
        }
        
        DispatchQueue.main.async {
            // 기존 assets에 새로운 assets 추가
            self.assets.append(contentsOf: newAssets)
            
            // 새로운 ScreenshotItemViewModel들 생성
            let newItemVMs = newAssets.map { asset in
                let item = ScreenshotItem(asset: asset)
                return ScreenshotRepository.shared.viewModel(for: item)
            }
            self.itemVMs.append(contentsOf: newItemVMs)
            
            self.currentIndex = endIndex
            self.hasMoreAssets = endIndex < allAssets.count
            self.isLoadingMore = false
        }
    }
    
    // 새로고침 (처음부터 다시 로드)
    func refresh() {
        fetchInitialScreenshots()
    }
    
    // 선택된 에셋 토글
    func toggleSelection(of asset: PHAsset) {
        let id = asset.localIdentifier
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
    
    //토글 단위가 ScreenshotItemViewModel
    func toggleSelection(of vm: ScreenshotItemViewModel) {
        let id = vm.id
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
    }
    
    // 현재 로드된 스크린샷만 모두 선택
    func selectAll() {
        assets.map(\.localIdentifier)
            .forEach { selectedIDs.insert($0) }
    }
    
    // 선택 해제
    func deselectAll() {
        selectedIDs.removeAll()
    }
    
    // 선택된 스크린샷 삭제
    func delete(assets toDelete: [PHAsset], completion: ((Bool, Error?) -> Void)? = nil) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(toDelete as NSFastEnumeration)
        }) { success, error in
            DispatchQueue.main.async {
                if success {
                    // 삭제 후 다시 페칭
                    self.fetchInitialScreenshots()
                    
                    // 선택된 ID 중 삭제된 에셋의 ID만 빼기
                    let deletedIDs = toDelete.map { $0.localIdentifier }
                    self.selectedIDs.subtract(deletedIDs)
                }
                completion?(success, error)
            }
        }
    }
}
