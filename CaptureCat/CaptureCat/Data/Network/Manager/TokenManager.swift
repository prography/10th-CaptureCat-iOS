//
//  TokenManager.swift
//  CaptureCat
//
//  Created by minsong kim on 7/25/25.
//

import Foundation

// 토큰 갱신의 동시성을 제어하는 Actor
actor TokenManager {
    static let shared = TokenManager()
    // 현재 진행 중인 토큰 갱신 Task
    private var currentRefreshTask: Task<Bool, Never>?
    
    private init() {}
    
    // MARK: - Public Methods
    /// 유효한 토큰 확보 (동시성 제어됨)
    /// - Returns: 토큰 갱신 성공 여부
    func ensureValidToken() async -> Bool {
        debugPrint("🔄 [TokenManager] ensureValidToken 호출됨")
        
        // 이미 진행 중인 갱신 작업이 있다면 그 결과를 기다림
        if let ongoingTask = currentRefreshTask {
            debugPrint("🔄 [TokenManager] 진행 중인 토큰 갱신 작업 발견 - 대기합니다...")
            let result = await ongoingTask.value
            debugPrint("🔄 [TokenManager] 대기 중이던 토큰 갱신 결과: \(result)")
            return result
        }
        
        // 새로운 토큰 갱신 작업 시작
        debugPrint("🔄 [TokenManager] 새로운 토큰 갱신 작업 시작 (단일 실행 보장됨)")
        let refreshTask = Task<Bool, Never> {
            await performTokenRefresh()
        }
        
        // 현재 진행 중인 작업으로 설정
        currentRefreshTask = refreshTask
        
        // 작업 완료까지 대기
        let result = await refreshTask.value
        
        // 작업 완료 후 정리
        currentRefreshTask = nil
        
        debugPrint("🔄 [TokenManager] 토큰 갱신 작업 완료: \(result)")
        return result
    }
    
    // MARK: - Private Methods
    
    /// 실제 토큰 갱신 수행
    private func performTokenRefresh() async -> Bool {
        debugPrint("🔄 [TokenManager] performTokenRefresh 시작")
        
        guard let refreshToken = KeyChainModule.read(key: .refreshToken),
              !refreshToken.isEmpty else {
            debugPrint("🔴 [TokenManager] RefreshToken이 없어서 토큰 갱신 불가")
            return false
        }
        
        do {
            debugPrint("🔄 [TokenManager] 토큰 갱신 API 호출 시작...")
            let builder = RefreshTokenBuilder(refreshToken: refreshToken)
            let response = try await performDirectTokenRefreshRequest(builder)
            debugPrint("✅ [TokenManager] 토큰 갱신 API 호출 성공")
            return true
        } catch {
            debugPrint("🔴 [TokenManager] 토큰 갱신 실패: \(error)")
            // 갱신 실패 시 안전한 토큰 정리
            await safelyCleanupTokens()
            // 토큰 갱신 실패 알림 발송 (메인 스레드에서)
            await MainActor.run {
                NotificationCenter.default.post(name: .tokenRefreshFailed, object: nil)
                debugPrint("📢 토큰 갱신 실패 알림 발송됨")
            }
            return false
        }
    }
    
    /// 직접 토큰 갱신 요청 수행 (NetworkManager 의존성 제거)
    private func performDirectTokenRefreshRequest<Builder: BuilderProtocol>(_ builder: Builder) async throws -> Builder.Response {
        // 실제 API URL 사용
        guard let baseURL = Bundle.main.baseURL else {
            throw NetworkError.urlNotFound
        }
        
        let fullURL = baseURL.appendingPathComponent(builder.path)
        var components = URLComponents(url: fullURL, resolvingAgainstBaseURL: false)
        components?.queryItems = builder.queries
        
        guard let url = components?.url else {
            throw NetworkError.urlNotFound
        }
        
        var request = URLRequest(url: url)
        builder.headers.forEach { (key, value) in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        request.httpMethod = builder.method.typeName
        
        if builder.method != .get {
            request.httpBody = try await builder.serializer.serialize(builder.parameters)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            debugPrint("🔴 Token Refresh HTTP Response를 가져올 수 없음")
            throw NetworkError.responseNotFound
        }
        
        debugPrint("📊 Token Refresh HTTP Status Code: \(httpResponse.statusCode)")
        
        switch httpResponse.statusCode {
        case 200...299:
            // 성공 시 헤더에서 새로운 토큰 추출 및 저장
            if let newAccessToken = httpResponse.value(forHTTPHeaderField: "Authorization"),
               let newRefreshToken = httpResponse.value(forHTTPHeaderField: "Refresh-Token") {
                
                // 기존 토큰 삭제 후 새 토큰 저장
                KeyChainModule.update(key: .accessToken, data: newAccessToken)
                KeyChainModule.update(key: .refreshToken, data: newRefreshToken)
                
                debugPrint("🔑 새로운 토큰 저장 완료")
                debugPrint("🔑 - New Access: \(newAccessToken.prefix(20))...")
                debugPrint("🔑 - New Refresh: \(newRefreshToken.prefix(20))...")
                
            } else {
                debugPrint("⚠️ 토큰 갱신 응답 헤더에서 새로운 토큰을 찾을 수 없음")
                throw NetworkError.unauthorized
            }
            
            debugPrint("✅ 토큰 갱신 성공: \(httpResponse.statusCode)")
            return try await builder.deserializer.deserialize(data)
            
        case 401:
            debugPrint("🔴 토큰 갱신 401 Unauthorized - RefreshToken 만료")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            // 401 오류 시 토큰 갱신 실패 알림 발송
            await MainActor.run {
                NotificationCenter.default.post(name: .tokenRefreshFailed, object: nil)
                debugPrint("📢 RefreshToken 만료로 인한 토큰 갱신 실패 알림 발송됨")
            }
            throw NetworkError.unauthorized
            
        default:
            debugPrint("🔴 토큰 갱신 예상하지 못한 HTTP 상태 코드: \(httpResponse.statusCode)")
            debugPrint("🔴 응답 내용: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw NetworkError.unknown(httpResponse.statusCode)
        }
    }
    
    /// 토큰을 안전하게 정리 (연쇄 삭제 방지)
    private func safelyCleanupTokens() async {
        debugPrint("🧹 안전한 토큰 정리 시작")
        KeyChainModule.delete(key: .accessToken)
        KeyChainModule.delete(key: .refreshToken)
        AccountStorage.shared.safeReset()
        debugPrint("🧹 토큰 정리 완료")
    }
    
    /// 현재 갱신 작업 상태 확인 (디버깅용)
    var isRefreshing: Bool {
        currentRefreshTask != nil
    }
}
