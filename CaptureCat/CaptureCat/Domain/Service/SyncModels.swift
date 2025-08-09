//
//  SyncModels.swift
//  CaptureCat
//
//  Created by minsong kim on 7/25/25.
//

import Foundation

/// 동기화 진행 상황을 추적하는 구조체
struct SyncProgress {
    let totalCount: Int
    let completedCount: Int
    let currentFileName: String
    let isCompleted: Bool
    
    var percentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
}

/// 동기화 완료 결과를 나타내는 구조체
struct SyncResult: Hashable {
    let totalCount: Int
    let successCount: Int
    let failedCount: Int
    let failedItems: [String] // 실패한 파일명들
    
    var isPartialSuccess: Bool {
        successCount > 0 && failedCount > 0
    }
    
    var isCompleteSuccess: Bool {
        failedCount == 0 && successCount > 0
    }
    
    var isCompleteFailure: Bool {
        successCount == 0 && totalCount > 0
    }
    
    var hasNoData: Bool {
        totalCount == 0
    }
} 
