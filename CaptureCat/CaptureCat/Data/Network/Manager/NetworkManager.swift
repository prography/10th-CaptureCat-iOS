//
//  NetworkManager.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import Foundation

final class NetworkManager {
    private let session: URLSession
    private var baseURL: URL
    
    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func fetchData<Builder: BuilderProtocol>(
        _ builder: Builder,
        isRetry: Bool = false,
        interceptors: [any NetworkInterceptor] = []
    ) async throws -> Builder.Response {
        var request = try await makeRequest(builder)
        for interceptor in interceptors {
            request = try await interceptor.willSend(request, builder: builder)
        }
        
        let (data, response) = try await session.data(for: request)
        
        logResponsedData(data)
        
        let httpResponse = try transformToHTTPResponse(from: response)
        
        logHTTPResponse(httpResponse)
        
        for interceptor in interceptors {
            try await interceptor.didReceive(response: httpResponse, data: data, builder: builder)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try await builder.deserializer.deserialize(data)
        default:
            let error = NetworkError(
                statusCode: httpResponse.statusCode,
                message: parseServerErrorMessage(from: data)
            )
            
            return try await handleNetworkError(error, builder: builder, isRetry: isRetry)
        }
    }
    
    private func handleNetworkError<Builder: BuilderProtocol>(
        _ error: NetworkError,
        builder: Builder,
        isRetry: Bool
    ) async throws -> Builder.Response {
        guard error == .unauthorized else {
            throw error
        }
        
        return try await reissueTokenAndRetry(builder: builder, isRetry: isRetry)
    }
    
    private func reissueTokenAndRetry<Builder: BuilderProtocol>(
        builder: Builder,
        isRetry: Bool
    ) async throws -> Builder.Response {
        guard !isRetry && builder.useAuthorization else {
            debugPrint("🔴 재시도 불가: isRetry=\(isRetry), useAuthorization=\(builder.useAuthorization)")
            throw NetworkError.unauthorized
        }
        
        try await reissueToken()
        
        return try await fetchData(
            builder,
            isRetry: true
        )
    }
    
    private func reissueToken() async throws {
        let result = await TokenManager.shared.ensureValidToken()
        
        switch result {
        case .success:
            return
        case .noRefreshToken, .expired, .networkError:
            await notifyRefreshFailed()
            throw NetworkError.unauthorized
        }
    }
    
    private func parseTokens(_ httpResponse: HTTPURLResponse) {
        if let accessToken = httpResponse.value(forHTTPHeaderField: "Authorization"),
           let refreshToken = httpResponse.value(forHTTPHeaderField: "Refresh-Token") {
            KeyChainModule.create(key: .accessToken, data: accessToken)
            KeyChainModule.create(key: .refreshToken, data: refreshToken)
        } else {
            debugPrint("⚠️ 응답 헤더에서 토큰을 찾을 수 없음")
        }
    }
    
    private func makeRequest<Builder: BuilderProtocol>(_ builder: Builder) async throws -> URLRequest {
        let fullURL = baseURL.appendingPathComponent(builder.path)
        
        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)
        
        components?.queryItems = builder.queries
        
        guard let url = components?.url else {
            debugPrint("🔴 URL 생성 실패!")
            throw NetworkError.urlNotFound
        }
        
        var request = URLRequest(url: url)
        builder.headers.forEach { (key, value) in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        if builder.useAuthorization {
            let accesstoken = KeyChainModule.read(key: .accessToken) ?? ""
            if accesstoken.isEmpty {
                debugPrint("⚠️ 인증이 필요하지만 AccessToken이 없음")
            } else {
                debugPrint("🔑 인증 토큰 사용: \(accesstoken.prefix(20))...")
            }
            request.setValue("\(accesstoken)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpMethod = builder.method.typeName
        
        if builder.method != .get {
            request.httpBody = try await builder.serializer.serialize(builder.parameters)
        }
        
        return request
    }
}

extension NetworkManager {
    private func parseServerErrorMessage(from data: Data) -> String? {
        do {
            let errorDTO = try JSONDecoder().decode(ErrorDTO.self, from: data)
            return errorDTO.error.message
        } catch {
            debugPrint("🔴 서버 에러 메시지 파싱 실패: \(error)")
            return nil
        }
    }
    
    private func logResponsedData(_ data: Data) {
        let responseString = String(data: data, encoding: .utf8)
        
        debugPrint("📥 Response Data: \(responseString ?? "[Binary Data - \(data.count) bytes]")")
    }
    
    private func logHTTPResponse(_ httpResponse: HTTPURLResponse) {
        debugPrint("📊 HTTP Status Code: \(httpResponse.statusCode)")
        debugPrint("📊 HTTP Headers: \(httpResponse.allHeaderFields)")
        debugPrint("📊 Response URL: \(httpResponse.url?.absoluteString ?? "nil")")
    }
    
    private func transformToHTTPResponse(from response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("🔴 HTTP Response를 가져올 수 없음")
            throw NetworkError.responseNotFound
        }
        
        return httpResponse
    }
    
    func notifyRefreshFailed() async {
        await MainActor.run {
            NotificationCenter.default.post(name: .tokenRefreshFailed, object: nil)
            debugPrint("📢 토큰 갱신 실패 알림 발송")
        }
    }
}
