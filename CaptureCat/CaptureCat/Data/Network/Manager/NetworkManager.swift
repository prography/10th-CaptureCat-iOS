//
//  NetworkManager.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import Foundation

class NetworkManager {
    private var baseURL: URL
    
    init(baseURL: URL) {
        self.baseURL = baseURL
    }
    
    // MARK: - Public
    func fetchData<Builder: BuilderProtocol>(_ builder: Builder) async throws -> Builder.Response {
        let request = try await makeRequest(builder)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 응답 데이터 로깅
        if let responseString = String(data: data, encoding: .utf8) {
            debugPrint("📥 Response Data: \(responseString)")
        } else {
            debugPrint("📥 Response Data: [Binary Data - \(data.count) bytes]")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("🔴 HTTP Response를 가져올 수 없음")
            throw NetworkError.responseNotFound
        }
        
        // 상세 응답 정보 로깅
        debugPrint("📊 HTTP Status Code: \(httpResponse.statusCode)")
        debugPrint("📊 HTTP Headers: \(httpResponse.allHeaderFields)")
        debugPrint("📊 Response URL: \(httpResponse.url?.absoluteString ?? "nil")")
        
        switch httpResponse.statusCode {
        case 200...299:
            debugPrint("✅ 성공 응답: \(httpResponse.statusCode)")
            return try await builder.deserializer.deserialize(data)
        case 400:
            debugPrint("🔴 400 Bad Request - 잘못된 요청")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.badRequest
        case 401:
            debugPrint("🔴 401 Unauthorized - 인증 실패")
            debugPrint("🔴 현재 토큰: \(KeyChainModule.read(key: .accessToken) ?? "없음")")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.unauthorized
        case 403:
            debugPrint("🔴 403 Forbidden - 권한 없음")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.forBidden
        case 404:
            debugPrint("🔴 404 Not Found - 리소스를 찾을 수 없음")
            debugPrint("🔴 요청 URL: \(request.url?.absoluteString ?? "nil")")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.responseNotFound
        case 429:
            debugPrint("🔴 429 Too Many Requests - 요청 한도 초과")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.tooManyRequests
        case 500:
            debugPrint("🔴 500 Internal Server Error - 서버 내부 오류")
            debugPrint("🔴 요청 URL: \(request.url?.absoluteString ?? "nil")")
            debugPrint("🔴 요청 Method: \(request.httpMethod ?? "nil")")
            debugPrint("🔴 요청 Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let body = request.httpBody {
                debugPrint("🔴 요청 Body: \(String(data: body, encoding: .utf8) ?? "[Binary Data - \(body.count) bytes]")")
            }
            debugPrint("🔴 서버 응답: \(String(data: data, encoding: .utf8) ?? "nil")")
            debugPrint("🔴 응답 Headers: \(httpResponse.allHeaderFields)")
            throw NetworkError.unknown(httpResponse.statusCode)
        default:
            debugPrint("🔴 예상하지 못한 HTTP 상태 코드: \(httpResponse.statusCode)")
            debugPrint("🔴 요청 URL: \(request.url?.absoluteString ?? "nil")")
            debugPrint("🔴 요청 Method: \(request.httpMethod ?? "nil")")
            debugPrint("🔴 요청 Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let body = request.httpBody {
                debugPrint("🔴 요청 Body: \(String(data: body, encoding: .utf8) ?? "[Binary Data - \(body.count) bytes]")")
            }
            debugPrint("🔴 서버 응답: \(String(data: data, encoding: .utf8) ?? "nil")")
            debugPrint("🔴 응답 Headers: \(httpResponse.allHeaderFields)")
            throw NetworkError.unknown(httpResponse.statusCode)
        }
    }
    
    func fetchLoginData<Builder: BuilderProtocol>(_ builder: Builder, isRetry: Bool = false) async throws -> Builder.Response {
        let request = try await makeRequest(builder)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // 응답 데이터 로깅
        if let responseString = String(data: data, encoding: .utf8) {
            debugPrint("📥 Login Response Data: \(responseString)")
        } else {
            debugPrint("📥 Login Response Data: [Binary Data - \(data.count) bytes]")
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("🔴 Login HTTP Response를 가져올 수 없음")
            throw NetworkError.responseNotFound
        }

        // 상세 응답 정보 로깅
        debugPrint("📊 Login HTTP Status Code: \(httpResponse.statusCode)")
        debugPrint("📊 Login HTTP Headers: \(httpResponse.allHeaderFields)")
        
        if let accessToken = httpResponse.value(forHTTPHeaderField: "Authorization"),
           let refreshToken = httpResponse.value(forHTTPHeaderField: "Refresh-Token") {
            KeyChainModule.create(key: .accessToken, data: accessToken)
            KeyChainModule.create(key: .refreshToken, data: refreshToken)
            debugPrint("🔑 토큰 저장 완료 - Access: \(accessToken.prefix(20))..., Refresh: \(refreshToken.prefix(20))...")
        } else {
            debugPrint("⚠️ 응답 헤더에서 토큰을 찾을 수 없음")
        }

        switch httpResponse.statusCode {
        case 200...299:
            debugPrint("✅ 로그인 성공: \(httpResponse.statusCode)")
            return try await builder.deserializer.deserialize(data)
        case 400:
            debugPrint("🔴 로그인 400 Bad Request")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.badRequest
        case 401:
            debugPrint("🔴 로그인 401 Unauthorized")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.unauthorized
        case 403:
            debugPrint("🔴 로그인 403 Forbidden")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.forBidden
        case 404:
            debugPrint("🔴 로그인 404 Not Found")
            debugPrint("🔴 요청 URL: \(request.url?.absoluteString ?? "nil")")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.responseNotFound
        case 429:
            debugPrint("🔴 로그인 429 Too Many Requests")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.tooManyRequests
        case 500:
            debugPrint("🔴 로그인 500 Internal Server Error")
            debugPrint("🔴 요청 URL: \(request.url?.absoluteString ?? "nil")")
            debugPrint("🔴 요청 Method: \(request.httpMethod ?? "nil")")
            debugPrint("🔴 요청 Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let body = request.httpBody {
                debugPrint("🔴 요청 Body: \(String(data: body, encoding: .utf8) ?? "[Binary Data - \(body.count) bytes]")")
            }
            debugPrint("🔴 서버 응답: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.internalServerError
        default:
            debugPrint("🔴 로그인 예상하지 못한 HTTP 상태 코드: \(httpResponse.statusCode)")
            debugPrint("🔴 요청 URL: \(request.url?.absoluteString ?? "nil")")
            debugPrint("🔴 요청 Method: \(request.httpMethod ?? "nil")")
            debugPrint("🔴 요청 Headers: \(request.allHTTPHeaderFields ?? [:])")
            if let body = request.httpBody {
                debugPrint("🔴 요청 Body: \(String(data: body, encoding: .utf8) ?? "[Binary Data - \(body.count) bytes]")")
            }
            debugPrint("🔴 서버 응답: \(String(data: data, encoding: .utf8) ?? "nil")")
            debugPrint("🔴 응답 Headers: \(httpResponse.allHeaderFields)")
            throw NetworkError.unknown(httpResponse.statusCode)
        }
    }
    
    // MARK: - Private
    private func makeRequest<Builder: BuilderProtocol>(_ builder: Builder) async throws -> URLRequest {
        debugPrint("🔧 URL 생성 시작 - Base: \(baseURL), Path: \(builder.path)")
        let fullURL = baseURL.appendingPathComponent(builder.path)
        debugPrint("🔧 appendingPathComponent 결과: \(fullURL)")
        
        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)
        debugPrint("🔧 URLComponents 생성: \(components?.description ?? "nil")")
        
        components?.queryItems = builder.queries
        debugPrint("🔧 Query Items 추가: \(components?.queryItems?.description ?? "nil")")
        
        guard let url = components?.url else {
            debugPrint("🔴 URL 생성 실패!")
            debugPrint("🔴 - baseURL: \(baseURL)")
            debugPrint("🔴 - builder.path: \(builder.path)")
            debugPrint("🔴 - fullURL: \(fullURL)")
            debugPrint("🔴 - components: \(components?.description ?? "nil")")
            debugPrint("🔴 - components.url: nil")
            throw NetworkError.urlNotFound
        }
        
        debugPrint("🔧 최종 URL 생성 성공: \(url)")
        
        
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
        
        // 상세 요청 정보 로깅
        debugPrint("📤 ===== REQUEST INFO =====")
        debugPrint("📤 URL: \(request.url?.absoluteString ?? "nil")")
        debugPrint("📤 Method: \(request.httpMethod ?? "nil")")
        debugPrint("📤 Headers: \(request.allHTTPHeaderFields ?? [:])")
        debugPrint("📤 Query Items: \(components?.queryItems?.map { "\($0.name)=\($0.value ?? "nil")" }.joined(separator: "&") ?? "none")")
        
        if let body = request.httpBody {
            if let bodyString = String(data: body, encoding: .utf8) {
                debugPrint("📤 Body (String): \(bodyString)")
            } else {
                debugPrint("📤 Body (Binary): \(body.count) bytes")
                // 이미지 데이터인 경우 첫 100바이트만 헥스로 표시
                let preview = body.prefix(100).map { String(format: "%02x", $0) }.joined()
                debugPrint("📤 Body Preview (Hex): \(preview)...")
            }
        } else {
            debugPrint("📤 Body: none")
        }
        
        debugPrint("📤 Builder Type: \(type(of: builder))")
        debugPrint("📤 Use Authorization: \(builder.useAuthorization)")
        debugPrint("📤 ========================")
        
        return request
    }
}
