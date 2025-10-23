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
    func fetchData<Builder: BuilderProtocol>(_ builder: Builder, isRetry: Bool = false) async throws -> Builder.Response {
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
            
            // 서버 에러 메시지 파싱 시도
            if let serverErrorMessage = parseServerErrorMessage(from: data) {
                throw NetworkError.serverError(serverErrorMessage)
            }
            throw NetworkError.badRequest
        case 401:
            debugPrint("🔴 401 Unauthorized - 인증 실패")
            debugPrint("🔴 현재 토큰: \(KeyChainModule.read(key: .accessToken) ?? "없음")")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            // 자동 토큰 갱신 및 재시도 로직
            return try await handleUnauthorizedError(builder: builder, isRetry: isRetry)
        case 403:
            debugPrint("🔴 403 Forbidden - 권한 없음")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            if let serverErrorMessage = parseServerErrorMessage(from: data) {
                throw NetworkError.serverError(serverErrorMessage)
            }
            throw NetworkError.forBidden
        case 404:
            debugPrint("🔴 404 Not Found - 리소스를 찾을 수 없음")
            debugPrint("🔴 요청 URL: \(request.url?.absoluteString ?? "nil")")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            if let serverErrorMessage = parseServerErrorMessage(from: data) {
                throw NetworkError.serverError(serverErrorMessage)
            }
            throw NetworkError.responseNotFound
        case 429:
            debugPrint("🔴 429 Too Many Requests - 요청 한도 초과")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            
            if let serverErrorMessage = parseServerErrorMessage(from: data) {
                throw NetworkError.serverError(serverErrorMessage)
            }
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
            
            if let serverErrorMessage = parseServerErrorMessage(from: data) {
                throw NetworkError.serverError(serverErrorMessage)
            }
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
        
        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("🔴 Login HTTP Response를 가져올 수 없음")
            throw NetworkError.responseNotFound
        }

        // 상세 응답 정보 로깅
        debugPrint("📊 Login HTTP Status Code: \(httpResponse.statusCode)")
        
        if let accessToken = httpResponse.value(forHTTPHeaderField: "Authorization"),
           let refreshToken = httpResponse.value(forHTTPHeaderField: "Refresh-Token") {
            KeyChainModule.create(key: .accessToken, data: accessToken)
            KeyChainModule.create(key: .refreshToken, data: refreshToken)
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
        let fullURL = baseURL.appendingPathComponent(builder.path)
        
        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)
        
        components?.queryItems = builder.queries
        
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
        
//        if let body = request.httpBody {
//            if let bodyString = String(data: body, encoding: .utf8) {
//                debugPrint("📤 Body (String): \(bodyString)")
//            } else {
//                debugPrint("📤 Body (Binary): \(body.count) bytes")
//                // 이미지 데이터인 경우 첫 100바이트만 헥스로 표시
//                let preview = body.prefix(100).map { String(format: "%02x", $0) }.joined()
//                debugPrint("📤 Body Preview (Hex): \(preview)...")
//            }
//        } else {
//            debugPrint("📤 Body: none")
//        }
        
        debugPrint("📤 Builder Type: \(type(of: builder))")
        debugPrint("📤 Use Authorization: \(builder.useAuthorization)")
        debugPrint("📤 ========================")
        
        return request
    }
}

extension NetworkManager {
    // MARK: - 토큰 갱신 관련 메서드
    
    /// 401 Unauthorized 에러 처리 (자동 토큰 갱신 및 재시도)
    private func handleUnauthorizedError<Builder: BuilderProtocol>(
        builder: Builder, 
        isRetry: Bool
    ) async throws -> Builder.Response {
        
        // 재시도가 아니고 Authorization이 필요한 요청인 경우에만 토큰 갱신 시도
        guard !isRetry && builder.useAuthorization else {
            debugPrint("🔴 재시도 불가: isRetry=\(isRetry), useAuthorization=\(builder.useAuthorization)")
            throw NetworkError.unauthorized
        }
        
        // RefreshToken 존재 여부 확인
        guard let refreshToken = KeyChainModule.read(key: .refreshToken),
              !refreshToken.isEmpty else {
            debugPrint("🔴 RefreshToken이 없어서 자동 갱신 불가")
            throw NetworkError.unauthorized
        }
        
        debugPrint("🔄 자동 토큰 갱신 시작...")
        debugPrint("🔄 - 기존 AccessToken: \(KeyChainModule.read(key: .accessToken)?.prefix(20) ?? "없음")...")
        debugPrint("🔄 - RefreshToken: \(refreshToken.prefix(20))...")
        
        // TokenManager를 통한 토큰 갱신 시도 (동시성 제어됨)
        let refreshSuccess = await TokenManager.shared.ensureValidToken()
        
        if refreshSuccess {
            debugPrint("✅ 토큰 갱신 성공! 원래 요청 재시도")
            debugPrint("✅ - 새 AccessToken: \(KeyChainModule.read(key: .accessToken)?.prefix(20) ?? "없음")...")
            
            // 원래 요청을 새 토큰으로 재시도
            return try await fetchData(builder, isRetry: true)
        } else {
            debugPrint("❌ 토큰 갱신 실패 - 로그인이 필요합니다")
            throw NetworkError.unauthorized
        }
    }
}

extension NetworkManager {
    /// RefreshToken도 Authorization 헤더와 함께 보내는 fetch 함수
    func fetchDataWithRefresh<Builder: BuilderProtocol>(_ builder: Builder, isRetry: Bool = false) async throws -> Builder.Response {
        var request = try await makeRequest(builder)
        
        // AccessToken
        if let accessToken = KeyChainModule.read(key: .accessToken), !accessToken.isEmpty {
            request.setValue(accessToken, forHTTPHeaderField: "Authorization")
            debugPrint("🔑 AccessToken 추가: \(accessToken.prefix(20))...")
        } else {
            debugPrint("⚠️ AccessToken 없음")
        }
        
        // RefreshToken
        if let refreshToken = KeyChainModule.read(key: .refreshToken), !refreshToken.isEmpty {
            request.setValue(refreshToken, forHTTPHeaderField: "Refresh-Token")
            debugPrint("🔑 RefreshToken 추가: \(refreshToken.prefix(20))...")
        } else {
            debugPrint("⚠️ RefreshToken 없음")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("🔴 HTTP Response를 가져올 수 없음")
            throw NetworkError.responseNotFound
        }
        
        debugPrint("📊 Status Code: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200...299:
            debugPrint("✅ 성공 응답: \(httpResponse.statusCode)")
            return try await builder.deserializer.deserialize(data)
        case 400:
            throw NetworkError.badRequest
            debugPrint("🔴 400")
        case 401:
            // 여기서는 굳이 토큰 갱신 로직을 안 돌리고 단순 실패 처리하거나
            // 필요하다면 handleUnauthorizedError 호출 가능
            throw NetworkError.unauthorized
            debugPrint("🔴 401")
        case 403:
            throw NetworkError.forBidden
            debugPrint("🔴 403")
        case 404:
            throw NetworkError.responseNotFound
            debugPrint("🔴 404")
        case 429:
            throw NetworkError.tooManyRequests
            debugPrint("🔴 429")
        case 500:
            throw NetworkError.internalServerError
            debugPrint("🔴 500")
        default:
            throw NetworkError.unknown(httpResponse.statusCode)
            debugPrint("🔴 \(httpResponse.statusCode)")
        }
    }
    
    // MARK: - Error Message Parsing
    private func parseServerErrorMessage(from data: Data) -> String? {
        do {
            let errorDTO = try JSONDecoder().decode(ErrorDTO.self, from: data)
            return errorDTO.error.message
        } catch {
            debugPrint("🔴 서버 에러 메시지 파싱 실패: \(error)")
            return nil
        }
    }
}
