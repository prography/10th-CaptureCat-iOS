//
//  TokenRefreshService.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import Foundation

protocol TokenRefreshProtocol {
    func refreshToken() async -> TokenRefreshResult
}

struct TokenRefreshService: TokenRefreshProtocol {
    private let baseURL: URL
    private let session: URLSession
    
    init(baseURL: URL = Bundle.main.baseURL!,
         session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func refreshToken() async -> TokenRefreshResult {
        debugPrint("🔄 [TokenRefreshService] performTokenRefresh 시작")
        
        guard let refreshToken = KeyChainModule.read(key: .refreshToken),
              !refreshToken.isEmpty else {
            debugPrint("🔴 [TokenRefreshService] RefreshToken 없음")
            return .noRefreshToken
        }
        
        do {
            debugPrint("🔄 [TokenRefreshService] 토큰 갱신 API 호출 시작...")
            let builder = RefreshTokenBuilder(refreshToken: refreshToken)
            _ = try await performRefreshRequest(builder)
            debugPrint("✅ [TokenRefreshService] 토큰 갱신 API 성공")
            return .success
        } catch let error as NetworkError {
            switch error {
            case .unauthorized:
                await handleRefreshFailure()
                return .expired
            default:
                debugPrint("🔴 [TokenRefreshService] NetworkError: \(error)")
                return .networkError(error)
            }
        } catch {
            debugPrint("🔴 [TokenRefreshService] 알 수 없는 에러: \(error)")
            return .networkError(error)
        }
    }
}

private extension TokenRefreshService {
    func performRefreshRequest<Builder: BuilderProtocol>(
        _ builder: Builder
    ) async throws -> Builder.Response {
        let url = baseURL.appendingPathComponent(builder.path)
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = builder.queries
        
        guard let url = components?.url else {
            throw NetworkError.urlNotFound
        }
        
        var request = URLRequest(url: url)
        builder.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.httpMethod = builder.method.typeName
        
        if builder.method != .get {
            request.httpBody = try await builder.serializer.serialize(builder.parameters)
        }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.responseNotFound
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            try handleSuccess(httpResponse)
            return try await builder.deserializer.deserialize(data)
        case 401:
            await notifyRefreshFailed()
            throw NetworkError.unauthorized
        default:
            throw NetworkError.unknown(httpResponse.statusCode)
        }
    }
    
    func handleSuccess(_ httpResponse: HTTPURLResponse) throws {
        guard
            let newAccessToken = httpResponse.value(forHTTPHeaderField: "Authorization"),
            let newRefreshToken = httpResponse.value(forHTTPHeaderField: "Refresh-Token")
        else {
            debugPrint("⚠️ 갱신 응답 헤더에서 토큰을 찾을 수 없음")
            throw NetworkError.unauthorized
        }
        
        KeyChainModule.update(key: .accessToken, data: newAccessToken)
        KeyChainModule.update(key: .refreshToken, data: newRefreshToken)
        
        debugPrint("🔑 새로운 토큰 저장 완료")
        debugPrint("🔑 - New Access: \(newAccessToken.prefix(20))...")
        debugPrint("🔑 - New Refresh: \(newRefreshToken.prefix(20))...")
    }
    
    func notifyRefreshFailed() async {
        await MainActor.run {
            NotificationCenter.default.post(name: .tokenRefreshFailed, object: nil)
            debugPrint("📢 토큰 갱신 실패 알림 발송")
        }
    }
    
    func handleRefreshFailure() async {
        debugPrint("🧹 안전한 토큰 정리 시작")
        KeyChainModule.delete(key: .accessToken)
        KeyChainModule.delete(key: .refreshToken)
        AccountStorage.shared.safeReset()
        debugPrint("🧹 토큰 정리 완료")
        
        await notifyRefreshFailed()
    }
}
