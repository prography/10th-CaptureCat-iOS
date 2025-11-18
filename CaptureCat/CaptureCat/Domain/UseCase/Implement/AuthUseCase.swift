//
//  AutoFlowUseCase.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import Foundation

final class AuthUseCase: AuthUseCaseProtocol {
    private let socialManager: SocialManager
    private let authService: AuthService
    private let sessionManager: SessionManaging
    private let appDataResetter: AppDataResetting
    private let autoLoginService: AutoLoginService
    
    init(
        socialManager: SocialManager,
        authService: AuthService,
        sessionManager: SessionManaging,
        appDataResetter: AppDataResetting,
        autoLoginService: AutoLoginService
    ) {
        self.socialManager = socialManager
        self.authService = authService
        self.sessionManager = sessionManager
        self.appDataResetter = appDataResetter
        self.autoLoginService = autoLoginService
    }
    
    func autoLogin() async -> AuthFlowResult {
        await autoLoginService.autoLogin()
    }
    
    func login(with provider: SocialProvider) async -> AuthFlowResult {
        switch provider {
        case .kakao:
            return await loginWithKakao()
        case .apple:
            return await loginWithApple()
        }
    }
    
    func logout() {
        sessionManager.clearSession()
        appDataResetter.resetAll()
    }
    
    func withdraw(reason: String) async -> Result<ResponseDTO, Error> {
        let result = await authService.withdraw(reason: reason)
        if case .success = result {
            sessionManager.clearSessionForWithdraw()
            appDataResetter.resetAll()
        }
        return result
    }
    
    func recentLoginTypes() -> Set<LogIn> {
        sessionManager.recentLoginTypes()
    }
}

private extension AuthUseCase {
    func loginWithKakao() async -> AuthFlowResult {
        let result = await socialManager.kakaoLogin()
        
        switch result {
        case .success(let token):
            debugPrint("🟡 카카오에서 토큰 값 가져오기 성공 \(token) 🟡")
            
            let kakaoSignIn = await authService.login(
                social: "kakao",
                idToken: token.idToken,
                authToken: token.authToken,
                nickname: nil
            )
            
            switch kakaoSignIn {
            case .success:
                sessionManager.markRecentLogin(.kakao)
                
                return .success
                
            case .failure(let failure):
                debugPrint("🟡🔴 카카오 로그인 완전 실패 \(failure.localizedDescription) 🟡🔴")
                
                // 409 에러 처리 - 무조건 팝업 표시
                if case NetworkError.conflict = failure {
                    return .needSignInPopup
                } else if case NetworkError.serverError(let message) = failure,
                          message.contains("이미 가입된 이메일") ||
                            message.contains("ALREADY_REGISTERED_EMAIL") {
                    return .needSignInPopup
                } else {
                    return .failure
                }
            }
            
        case .failure(let failure):
            debugPrint("🟡🔴 카카오에서 토큰 값 가져오기 실패 \(failure.localizedDescription) 🟡🔴")
            return .failure
        }
    }
    
    func loginWithApple() async -> AuthFlowResult {
        let result = await socialManager.appleLogin()
        
        switch result {
        case .success(let token):
            let appleSignIn = await authService.login(
                social: "apple",
                idToken: nil,
                authToken: token.0,
                nickname: token.1
            )
            
            switch appleSignIn {
            case .success:
                sessionManager.markRecentLogin(.apple)
                return .success
            case .failure(let failure):
                debugPrint("🔴🍎 apple sign in 함수 실패 \(failure.localizedDescription)🔴🍎")
                
                // 409 에러 처리 - 무조건 팝업 표시
                if case NetworkError.conflict = failure {
                    return .needSignInPopup
                } else if case NetworkError.serverError(let message) = failure,
                          message.contains("이미 가입된 이메일") ||
                            message.contains("ALREADY_REGISTERED_EMAIL") {
                    return .needSignInPopup
                } else {
                    return .failure
                }
            }
            
        case .failure(let failure):
            debugPrint("🔴🍎🔴 애플 토큰 실패 \(failure.localizedDescription) 🔴🍎🔴")
            return .failure
        }
    }
}
