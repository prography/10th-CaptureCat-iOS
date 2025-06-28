//
//  ScreenshotManager.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI
import Photos
import Combine

struct ScreenshotGroup: Identifiable {
    let id: Date
    var assets: [PHAsset]
}

// Photos 라이브러리에서 “스크린샷”만 가져와 관리하고, 선택·삭제 등의 로직을 처리하는 매니저
final class ScreenshotManager: ObservableObject {
    @Published private(set) var assets: [PHAsset] = []
    @Published var selectedIDs: Set<String> = []
    @Published private(set) var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // 전체 스크린샷 개수
    var totalCount: Int {
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
                self.fetchScreenshots()
            }
        }
    }
    
    // 스크린샷만 필터링해서 assets에 할당
    private func fetchScreenshots() {
        isLoading = true
        
        let options = PHFetchOptions()
        // 스크린샷 미디어 서브타입 필터
        options.predicate = NSPredicate(
            format: "mediaSubtype & %d != 0",
            PHAssetMediaSubtype.photoScreenshot.rawValue
        )
        options.sortDescriptors = [
            NSSortDescriptor(key: "creationDate", ascending: false)
        ]
        
        let all = PHAsset.fetchAssets(with: .image, options: options)
        var arr: [PHAsset] = []
        all.enumerateObjects { asset, _, _ in
            arr.append(asset)
        }
        
        DispatchQueue.main.async {
            self.assets = arr
            self.isLoading = false
        }
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
    
    // 모든 스크린샷 선택
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
                    self.fetchScreenshots()
                    
                    // 선택된 ID 중 삭제된 에셋의 ID만 빼기
                    let deletedIDs = toDelete.map { $0.localIdentifier }
                    self.selectedIDs.subtract(deletedIDs)
                }
                completion?(success, error)
            }
        }
    }
}
