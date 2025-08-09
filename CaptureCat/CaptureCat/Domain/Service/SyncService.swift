//
//  SyncService.swift
//  CaptureCat
//
//  Created by minsong kim on 7/25/25.
//

import Foundation
import UIKit

@MainActor
final class SyncService: ObservableObject {
    static let shared = SyncService()
    
    @Published var syncProgress = SyncProgress(
        totalCount: 0,
        completedCount: 0,
        currentFileName: "",
        isCompleted: false
    )
    
    private let batchSize = 5 // 한 번에 업로드할 이미지 개수 (서버 부하 고려)
    private let maxRetries = 3 // 최대 재시도 횟수
    
    private init() {}
    
    /// 로컬 스크린샷을 서버로 동기화
    func syncLocalScreenshotsToServer() async -> SyncResult {
        debugPrint("🔄 동기화 시작")
        
        // 0. 토큰 상태 확인
//        guard let accessToken = AccountStorage.shared.accessToken, !accessToken.isEmpty else {
//            debugPrint("❌ 동기화 실패: 유효한 액세스 토큰이 없습니다")
//            return SyncResult(totalCount: 0, successCount: 0, failedCount: 0, failedItems: [])
//        }
//        debugPrint("✅ 동기화 토큰 확인 완료: \(accessToken.prefix(20))...")
        
        // 1. 로컬 스크린샷 조회
        guard let localScreenshots = try? SwiftDataManager.shared.fetchAllEntities(),
              !localScreenshots.isEmpty else {
            debugPrint("📱 로컬에 동기화할 데이터가 없습니다")
            return SyncResult(totalCount: 0, successCount: 0, failedCount: 0, failedItems: [])
        }
        
        debugPrint("📱 로컬에서 \(localScreenshots.count)개 스크린샷 발견")
        
        // 2. 진행상황 초기화
        updateProgress(total: localScreenshots.count, completed: 0, current: "동기화 준비 중...")
        
        // 3. 배치 단위로 처리
        var successCount = 0
        var failedItems: [String] = []
        let batches = localScreenshots.chunked(into: batchSize)
        
        for (batchIndex, batch) in batches.enumerated() {
            debugPrint("🔄 배치 \(batchIndex + 1)/\(batches.count) 처리 시작 (\(batch.count)개)")
            
            let batchResult = await processBatch(batch, batchIndex: batchIndex + 1, totalBatches: batches.count)
            successCount += batchResult.successCount
            failedItems.append(contentsOf: batchResult.failedItems)
            
            let currentProgress = successCount + failedItems.count
            updateProgress(
                total: localScreenshots.count,
                completed: currentProgress,
                current: "동기화 중... (\(currentProgress)/\(localScreenshots.count))"
            )
            
            // 배치 간 잠시 대기 (서버 부하 방지)
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5초
        }
        
        // 4. 완료 상태 업데이트
        syncProgress = SyncProgress(
            totalCount: localScreenshots.count,
            completedCount: localScreenshots.count,
            currentFileName: "동기화 완료!",
            isCompleted: true
        )
        
        let result = SyncResult(
            totalCount: localScreenshots.count,
            successCount: successCount,
            failedCount: failedItems.count,
            failedItems: failedItems
        )
        
        debugPrint("✅ 동기화 완료: 성공 \(successCount)개, 실패 \(failedItems.count)개")
        return result
    }
    
    /// 배치 단위로 스크린샷 처리
    private func processBatch(_ screenshots: [Screenshot], batchIndex: Int, totalBatches: Int) async -> (successCount: Int, failedItems: [String]) {
        var imageDatas: [Data] = []
        var imageMetas: [PhotoDTO] = []
        var successfulIds: [String] = []
        var failedItems: [String] = []
        
        // 1. 각 스크린샷의 이미지 데이터 로드
        for screenshot in screenshots {
            updateProgress(
                total: syncProgress.totalCount,
                completed: syncProgress.completedCount,
                current: "이미지 로드 중: \(screenshot.fileName)"
            )
            
            do {
                // PHAsset에서 이미지 데이터 로드
                if let imageData = await loadImageData(for: screenshot) {
                    imageDatas.append(imageData)
                    imageMetas.append(PhotoDTO(
                        id: screenshot.id,
                        fileName: screenshot.fileName,
                        createDate: screenshot.createDate,
                        tags: screenshot.tags,
                        isFavorite: screenshot.isFavorite,
                        imageData: imageData
                    ))
                    successfulIds.append(screenshot.id)
                    debugPrint("✅ 이미지 로드 성공: \(screenshot.fileName)")
                } else {
                    failedItems.append(screenshot.fileName)
                    debugPrint("❌ 이미지 로드 실패: \(screenshot.fileName)")
                }
            } catch {
                failedItems.append(screenshot.fileName)
                debugPrint("❌ 이미지 로드 오류: \(screenshot.fileName) - \(error)")
            }
        }
        
        // 2. 서버 업로드
        if !imageDatas.isEmpty {
            updateProgress(
                total: syncProgress.totalCount,
                completed: syncProgress.completedCount,
                current: "서버 업로드 중... (배치 \(batchIndex)/\(totalBatches))"
            )
            
            let uploadResult = await uploadToServer(imageDatas: imageDatas, imageMetas: imageMetas)
            
            if uploadResult {
                // 3. 업로드 성공 시 로컬에서 삭제
                for id in successfulIds {
                    do {
                        try SwiftDataManager.shared.delete(id: id)
                        debugPrint("🗑️ 로컬에서 삭제 완료: \(id)")
                    } catch {
                        debugPrint("⚠️ 로컬 삭제 실패: \(id) - \(error)")
                    }
                }
                return (successCount: successfulIds.count, failedItems: failedItems)
            } else {
                // 업로드 실패 시 모든 파일을 실패 목록에 추가
                let allFileNames = imageMetas.map { $0.fileName }
                failedItems.append(contentsOf: allFileNames)
                return (successCount: 0, failedItems: failedItems)
            }
        }
        
        return (successCount: 0, failedItems: failedItems)
    }
    
    /// PHAsset에서 이미지 데이터 로드
    private func loadImageData(for screenshot: Screenshot) async -> Data? {
        // PHAsset ID를 사용하여 이미지 로드
        guard let fullImage = await PhotoLoader.shared.requestFullImage(id: screenshot.id) else {
            return nil
        }
        
        // JPEG 형태로 변환 (압축)
        return fullImage.jpegData(compressionQuality: 0.8)
    }
    
    /// 서버로 이미지 업로드
    private func uploadToServer(imageDatas: [Data], imageMetas: [PhotoDTO]) async -> Bool {
        let result = await ImageService.shared.uploadImages(imageDatas: imageDatas, imageMetas: imageMetas)
        
        switch result {
        case .success:
            debugPrint("✅ 서버 업로드 성공: \(imageDatas.count)개")
            return true
        case .failure(let error):
            debugPrint("❌ 서버 업로드 실패: \(error)")
            return false
        }
    }
    
    /// 진행상황 업데이트
    private func updateProgress(total: Int, completed: Int, current: String) {
        syncProgress = SyncProgress(
            totalCount: total,
            completedCount: completed,
            currentFileName: current,
            isCompleted: false
        )
    }
}
