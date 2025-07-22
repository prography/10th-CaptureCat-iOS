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

import Photos
import UIKit

enum AssetDataError: Error {
    case noData
    case cancelled
}

/// PHAsset → Data 변환
extension PHAsset {
    /// 썸네일 크기로 JPEG Data 요청
    /// - Parameters:
    ///   - targetSize: 원하는 썸네일 크기
    ///   - compressionQuality: JPEG 압축 퀄리티 (0.0 ~ 1.0)
    func requestThumbnailData(
        targetSize: CGSize,
        compressionQuality: CGFloat = 0.8
    ) async throws -> Data {
        try await withCheckedThrowingContinuation { cont in
            let options = PHImageRequestOptions()
            options.isSynchronous = false
            options.deliveryMode = .highQualityFormat
            options.resizeMode = .exact
            options.isNetworkAccessAllowed = true
            
            PHImageManager.default().requestImage(
                for: self,
                targetSize: targetSize,
                contentMode: .aspectFill,
                options: options
            ) { image, info in
                if let image = image,
                   let data = image.jpegData(compressionQuality: compressionQuality) {
                    cont.resume(returning: data)
                } else if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                    cont.resume(throwing: AssetDataError.cancelled)
                } else {
                    cont.resume(throwing: AssetDataError.noData)
                }
            }
        }
    }
    
    /// 원본(full‑size) 이미지 Data 요청
    /// - Parameter compressionQuality: (선택) JPEG 압축 퀄리티. nil이면 원본 포맷 그대로 반환
    func requestFullImageData(
        compressionQuality: CGFloat? = nil
    ) async -> Data? {
            try? await withCheckedThrowingContinuation { cont in
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                
                // iOS 13+ 권장: requestImageDataAndOrientation
                PHImageManager.default().requestImageDataAndOrientation(
                    for: self,
                    options: options
                ) { data, _, _, info in
                    if let data = data {
                        // 압축 퀄리티 지정 시 UIImage로 변환 후 재압축
                        if let q = compressionQuality,
                           let uiImage = UIImage(data: data),
                           let jpeg = uiImage.jpegData(compressionQuality: q) {
                            cont.resume(returning: jpeg)
                        } else {
                            cont.resume(returning: data)
                        }
                    } else if let cancelled = info?[PHImageCancelledKey] as? Bool, cancelled {
                        cont.resume(throwing: AssetDataError.cancelled)
                    } else {
                        cont.resume(throwing: AssetDataError.noData)
                    }
                    
                }
            
        }
    }
    
    /// 원본 파일(Byte 그대로) 데이터를 가져오는 더 “로우 레벨” 방법
    /// (EXIF 등 포함한 원본 파일 그대로)
    func requestOriginalFileData() async throws -> Data {
        try await withCheckedThrowingContinuation { cont in
            // assetResources 중 photo 타입 리소스 선택
            let resources = PHAssetResource.assetResources(for: self)
            guard let resource = resources.first(where: {
                $0.type == .fullSizePhoto || $0.type == .photo
            }) else {
                cont.resume(throwing: AssetDataError.noData)
                return
            }
            
            let options = PHAssetResourceRequestOptions()
            options.isNetworkAccessAllowed = true
            
            var data = Data()
            PHAssetResourceManager.default().requestData(
                for: resource,
                options: options,
                dataReceivedHandler: { chunk in
                    data.append(chunk)
                },
                completionHandler: { error in
                    if let err = error {
                        cont.resume(throwing: err)
                    } else {
                        cont.resume(returning: data)
                    }
                }
            )
        }
    }
}
