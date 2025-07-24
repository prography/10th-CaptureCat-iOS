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
}

/// 즐겨찾기 상태 변경 정보
struct FavoriteStatusInfo {
    let imageId: String
    let isFavorite: Bool
} 