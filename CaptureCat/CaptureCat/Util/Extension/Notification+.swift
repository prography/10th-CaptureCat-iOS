//
//  Notification+.swift
//  CaptureCat
//
//  Created by Assistant on 1/15/25.
//

import Foundation

extension Notification.Name {
    /// 토큰 갱신 실패 시 로그인 화면을 표시하기 위한 알림
    static let tokenRefreshFailed = Notification.Name("tokenRefreshFailed")
    
    /// 동기화 완료 알림
    static let syncCompleted = Notification.Name("syncCompleted")
}
