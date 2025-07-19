//
//  HomeViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI
import Photos
import Combine

final class HomeViewModel: ObservableObject {
    @Published var items: [ScreenshotItem] = []
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter
    }()
    
    private var cancellables = Set<AnyCancellable>()
    
    /// 스크린샷 데이터를 SwiftData에서 가져와 PHAsset으로부터 imageData, createDate, tags를 추출
    func loadScreenshotsFromLocal() {
        let savedScreenshots = SwiftDataManager.shared.fetchAllScreenshots()
        
        // 동기 옵션: 빠르게 로드하고 싶다면 isSynchronous = true
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isSynchronous = true
        
        var newItems: [ScreenshotItem] = []
        
        for shot in savedScreenshots {
            let fetchResult = PHAsset.fetchAssets(
                withLocalIdentifiers: [shot.fileName],
                options: nil
            )
            guard let asset = fetchResult.firstObject else { continue }
            
            // 이미지 데이터 요청
            PHImageManager.default()
                .requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                    guard let data = data else { return }
                    let date = asset.creationDate ?? Date()
                    let item = ScreenshotItem(
                        imageData: data,
                        createDate: self.dateFormatter.string(from: date),
                        tags: shot.tags
                    )
                    newItems.append(item)
                }
        }
        
        // 메인 스레드에서 published 업데이트
        DispatchQueue.main.async {
            self.items = newItems
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
