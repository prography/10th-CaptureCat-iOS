//
//  Notification+.swift
//  CaptureCat
//
//  Created by Assistant on 1/15/25.
//

import Foundation

extension Notification.Name {
    /// 즐겨찾기 상태 변경 알림
    static let favoriteStatusChanged = Notification.Name("favoriteStatusChanged")
    /// 태그 편집 완료 알림
    static let tagEditCompleted = Notification.Name("tagEditCompleted")
    /// 토큰 갱신 실패 시 로그인 화면을 표시하기 위한 알림
    static let tokenRefreshFailed = Notification.Name("tokenRefreshFailed")
    /// 낙관적 업데이트 완료 알림 (즉시 UI 반영용)
    static let optimisticUpdateCompleted = Notification.Name("optimisticUpdateCompleted")
    /// 서버 동기화 실패 알림 (롤백 필요시)
    static let serverSyncFailed = Notification.Name("serverSyncFailed")
    /// 동기화 완료 알림
    static let syncCompleted = Notification.Name("syncCompleted")
}

/// 즐겨찾기 상태 변경 정보
struct FavoriteStatusInfo {
    let imageId: String
    let isFavorite: Bool
}
