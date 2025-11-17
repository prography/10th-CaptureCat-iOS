//
//  TokenRefreshResult.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import Foundation

enum TokenRefreshResult {
    case success
    case noRefreshToken
    case expired
    case networkError(Error)
}
