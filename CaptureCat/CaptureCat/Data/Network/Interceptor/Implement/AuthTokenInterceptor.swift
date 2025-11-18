//
//  AuthTokenInterceptor.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import UIKit

struct AuthTokenInterceptor: NetworkInterceptor {
    func willSend<Builder: BuilderProtocol>(
        _ request: URLRequest,
        builder: Builder
    ) async throws -> URLRequest {
        var request = request
        
        // RefreshToken
        if builder.useRefreshToken {
            if let refreshToken = KeyChainModule.read(key: .refreshToken),
               !refreshToken.isEmpty {
                request.setValue(refreshToken, forHTTPHeaderField: "Refresh-Token")
                debugPrint("🔑 RefreshToken 추가: \(refreshToken.prefix(20))...")
            } else {
                debugPrint("⚠️ RefreshToken 없음 (useRefreshToken=true)")
            }
        }
        
        return request
    }
}
