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
    
    // 서버 이미지용 URLCache (디스크 캐싱)
    private let urlCache: URLCache
    
    private init() {
        // URLCache 설정 (100MB 메모리, 500MB 디스크)
        self.urlCache = URLCache(
            memoryCapacity: 100 * 1024 * 1024,  // 100MB
            diskCapacity: 500 * 1024 * 1024,    // 500MB
            diskPath: "server_image_cache"
        )
        
        // NSCache 메모리 제한 설정
        cache.totalCostLimit = 200 * 1024 * 1024  // 200MB
        cache.countLimit = 500  // 최대 500개 이미지
    }
    
    // MARK: - PHAsset (로컬 이미지) 메서드들
    
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
    
    // MARK: - 서버 이미지 캐싱 메서드들
    
    /// 서버 URL에서 이미지를 다운로드하고 캐싱 (썸네일 크기 지정 가능)
    func requestServerImage(
        url: URL,
        targetSize: CGSize? = nil
    ) async -> UIImage? {
        let cacheKey = cacheKey(for: url, size: targetSize)
        
        // 1) 메모리 캐시 확인
        if let cached = cache.object(forKey: cacheKey as NSString) {
            debugPrint("✅ 메모리 캐시에서 이미지 로드: \(url.lastPathComponent)")
            return cached
        }
        
        // 2) 디스크 캐시 확인
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
        if let cachedResponse = urlCache.cachedResponse(for: request),
           let image = UIImage(data: cachedResponse.data) {
            debugPrint("✅ 디스크 캐시에서 이미지 로드: \(url.lastPathComponent)")
            
            // 크기 조정이 필요한 경우
            let finalImage = targetSize != nil ? resizeImage(image, to: targetSize!) : image
            
            // 메모리 캐시에도 저장
            cache.setObject(finalImage, forKey: cacheKey as NSString)
            return finalImage
        }
        
        // 3) 서버에서 다운로드
        return await downloadAndCacheServerImage(url: url, targetSize: targetSize)
    }
    
    /// 서버 이미지 풀사이즈 다운로드
    func requestFullServerImage(url: URL) async -> UIImage? {
        return await requestServerImage(url: url, targetSize: nil)
    }
    
    /// 서버 이미지 썸네일 다운로드
    func requestServerThumbnail(url: URL, size: CGSize) async -> UIImage? {
        return await requestServerImage(url: url, targetSize: size)
    }
    
    // MARK: - Private Helper Methods
    
    /// 서버에서 이미지 다운로드 및 캐싱
    private func downloadAndCacheServerImage(url: URL, targetSize: CGSize?) async -> UIImage? {
        do {
            debugPrint("🔄 서버에서 이미지 다운로드 시작: \(url.lastPathComponent)")
            
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let image = UIImage(data: data) else {
                debugPrint("❌ 이미지 데이터 변환 실패: \(url.lastPathComponent)")
                return nil
            }
            
            // 크기 조정이 필요한 경우
            let finalImage = targetSize != nil ? resizeImage(image, to: targetSize!) : image
            
            // 메모리 캐시에 저장
            let cacheKey = cacheKey(for: url, size: targetSize)
            cache.setObject(finalImage, forKey: cacheKey as NSString)
            
            // 디스크 캐시에 저장 (원본 데이터)
            let cachedResponse = CachedURLResponse(response: response, data: data)
            urlCache.storeCachedResponse(cachedResponse, for: request)
            
            debugPrint("✅ 서버 이미지 다운로드 및 캐싱 완료: \(url.lastPathComponent)")
            return finalImage
            
        } catch {
            debugPrint("❌ 서버 이미지 다운로드 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// 이미지 크기 조정
    private func resizeImage(_ image: UIImage, to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// 캐시 키 생성 (URL + 크기 정보)
    private func cacheKey(for url: URL, size: CGSize?) -> String {
        if let size = size {
            return "\(url.absoluteString)_\(Int(size.width))x\(Int(size.height))"
        } else {
            return url.absoluteString
        }
    }
    
    // MARK: - Cache Management
    
    /// 특정 ID/URL의 캐시 삭제
    func clearCache(for id: String) {
        cache.removeObject(forKey: id as NSString)
    }
    
    /// 특정 URL의 캐시 삭제
    func clearServerImageCache(for url: URL) {
        // 메모리 캐시 삭제 (모든 크기 변형 포함)
        let baseKey = url.absoluteString
        cache.removeObject(forKey: baseKey as NSString)
        
        // 디스크 캐시 삭제
        let request = URLRequest(url: url)
        urlCache.removeCachedResponse(for: request)
    }
    
    /// 모든 서버 이미지 캐시 삭제
    func clearAllServerImageCache() {
        urlCache.removeAllCachedResponses()
        debugPrint("🗑️ 모든 서버 이미지 캐시 삭제 완료")
    }
    
    /// 캐시 상태 정보
    func cacheInfo() {
        debugPrint("📊 캐시 정보:")
        debugPrint("📊 - 메모리 캐시 사용량: \(cache.totalCostLimit / 1024 / 1024)MB")
        debugPrint("📊 - 디스크 캐시 사용량: \(urlCache.currentDiskUsage / 1024 / 1024)MB / \(urlCache.diskCapacity / 1024 / 1024)MB")
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
