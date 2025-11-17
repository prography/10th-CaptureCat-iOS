//
//  TokenParsingInterceptor.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import UIKit

struct TokenParsingInterceptor: NetworkInterceptor {
    func didReceive<Builder: BuilderProtocol>(
        response: HTTPURLResponse,
        data: Data,
        builder: Builder
    ) async throws {
        if let accessToken = response.value(forHTTPHeaderField: "Authorization"),
           let refreshToken = response.value(forHTTPHeaderField: "Refresh-Token") {
            KeyChainModule.create(key: .accessToken, data: accessToken)
            KeyChainModule.create(key: .refreshToken, data: refreshToken)
        } else {
            debugPrint("⚠️ 응답 헤더에서 토큰을 찾을 수 없음")
        }
    }
}
