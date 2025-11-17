//
//  TokenManager.swift
//  CaptureCat
//
//  Created by minsong kim on 7/25/25.
//

import Foundation

// 토큰 갱신의 동시성을 제어하는 Actor
actor TokenManager {
    static let shared = TokenManager(
        service: TokenRefreshService()
    )
    private var currentRefreshTask: Task<TokenRefreshResult, Never>?
    private let service: TokenRefreshService
    
    private init(service: TokenRefreshService) {
        self.service = service
    }
    
    // MARK: - Public Methods
    func ensureValidToken() async -> TokenRefreshResult {
        debugPrint("🔄 [TokenManager] ensureValidToken 호출됨")
        
        if let ongoingTask = currentRefreshTask {
            return await ongoingTask.value
        }
        
        // 새로운 토큰 갱신 작업 시작
        let refreshTask = Task<TokenRefreshResult, Never> {
            await service.refreshToken()
        }
        
        currentRefreshTask = refreshTask
        let result = await refreshTask.value
        currentRefreshTask = nil
        
        debugPrint("🔄 [TokenManager] 토큰 갱신 작업 완료: \(result)")
        return result
    }
    
    var isRefreshing: Bool {
        currentRefreshTask != nil
    }
}
