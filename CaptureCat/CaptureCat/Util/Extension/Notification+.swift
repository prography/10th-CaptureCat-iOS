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
    // tagEditCompleted 알림 삭제됨 - 홈뷰 NotificationCenter 사용 중단
    /// 토큰 갱신 실패 시 로그인 화면을 표시하기 위한 알림
    static let tokenRefreshFailed = Notification.Name("tokenRefreshFailed")
    // optimisticUpdateCompleted 알림 삭제됨 - 홈뷰 NotificationCenter 사용 중단
    // serverSyncFailed 알림 삭제됨 - 홈뷰 NotificationCenter 사용 중단
    /// 동기화 완료 알림
    static let syncCompleted = Notification.Name("syncCompleted")
    // loginSuccessCompleted 알림 삭제됨 - 홈뷰 NotificationCenter 사용 중단
    // imageSaveCompleted 알림 삭제됨 - 홈뷰 NotificationCenter 사용 중단
}

/// 즐겨찾기 상태 변경 정보
struct FavoriteStatusInfo {
    let imageId: String
    let isFavorite: Bool
}
