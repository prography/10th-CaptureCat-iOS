//
//  PhotoLoader.swift
//  CaptureCat
//
//  Created by minsong kim on 7/20/25.
//

import UIKit
import Photos

final class PhotoLoader {
    static let shared = PhotoLoader()
    
    // 메모리 캐시 (ID → UIImage)
    private let cache = NSCache<NSString, UIImage>()
    private let imageManager = PHCachingImageManager()
    
    private init() {}
    
    // 앱 실행 직후 혹은 스크린샷 리스트 페칭 뒤에…
    func prefetch(ids: [String], size: CGSize) {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        let opts = PHImageRequestOptions()
        opts.isNetworkAccessAllowed = true
        opts.deliveryMode = .highQualityFormat
        imageManager.startCachingImages(
            for: assets.objects(at: IndexSet(0..<assets.count)),
            targetSize: size,
            contentMode: .aspectFill,
            options: opts
        )
    }
    
    /// PHAsset.localIdentifier로 UIImage를 비동기 반환
    func requestImage(
        id: String,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .aspectFill,
        options: PHImageRequestOptions = {
            let opt = PHImageRequestOptions()
            opt.isNetworkAccessAllowed = true
            opt.deliveryMode = .highQualityFormat
            return opt
        }()
    ) async -> UIImage? {
        // 1) 캐시 확인
        if let cached = cache.object(forKey: id as NSString) {
            return cached
        }
        
        // 2) PHAsset 검색
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        print("Fetched \(assets.count) assets for id:", id)
        guard let asset = assets.firstObject else {
            return nil
        }
        
        // 3) 비동기 이미지 요청 & 캐싱
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options
            ) { image, _ in
                if let img = image {
                    self.cache.setObject(img, forKey: id as NSString)
                }
                continuation.resume(returning: image)
            }
        }
    }
    
    /// PHAsset에서 풀사이즈 이미지를 가져올 때
    func requestFullImage(
        id: String,
        options: PHImageRequestOptions = {
            let opt = PHImageRequestOptions()
            opt.isNetworkAccessAllowed = true
            opt.deliveryMode = .highQualityFormat
            return opt
        }()
    ) async -> UIImage? {
        await requestImage(id: id, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: options)
    }
    
    /// 캐시 삭제
    func clearCache(for id: String) {
        cache.removeObject(forKey: id as NSString)
    }
}
