//
//  AutoLoginService.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import AuthenticationServices
import Foundation
import KakaoSDKUser

protocol AutoLoginProtocol {
    func autoLogin() async -> AuthFlowResult
}

final class AutoLoginService: AutoLoginProtocol {
    func autoLogin() async -> AuthFlowResult {
        let hasAppleToken = KeyChainModule.read(key: .appleToken)?.isEmpty == false
        let hasKakaoToken = KeyChainModule.read(key: .kakaoToken)?.isEmpty == false
        
        if hasAppleToken, let appleId = KeyChainModule.read(key: .appleToken) {
            return await checkAppleLoginStatus(appleId: appleId)
        } else if hasKakaoToken {
            return await checkKakaoLoginStatus()
        } else {
            return .failure
        }
    }
}

private extension AutoLoginService {
    func checkAppleLoginStatus(appleId: String) async -> AuthFlowResult {
        let provider = ASAuthorizationAppleIDProvider()
        
        let (state, error) = await withCheckedContinuation { continuation in
            provider.getCredentialState(forUserID: appleId) { state, error in
                continuation.resume(returning: (state, error))
            }
        }
        
        if let error = error {
            debugPrint("🍏❌ [AutoLoginUseCase] Apple ID 상태 확인 실패: \(error.localizedDescription)")
            return handleAppleLoginFallback(error: error)
        }
        
        switch state {
        case .authorized:
            debugPrint("🍏✅ [AutoLoginUseCase] Apple ID 인증 유효 - 자동 로그인 성공")
            return .success
        case .revoked:
            debugPrint("🍏⚠️ [AutoLoginUseCase] Apple ID 인증 취소됨 - 토큰 정리 후 게스트 모드")
            cleanupAppleTokens()
            return .failure
        case .notFound:
            debugPrint("🍏⚠️ [AutoLoginUseCase] Apple ID를 찾을 수 없음 - 토큰 정리 후 게스트 모드")
            cleanupAppleTokens()
            return .failure
            
        default:
            debugPrint("🍏⚠️ [AutoLoginUseCase] Apple ID 상태 알 수 없음: \(state.rawValue) - 게스트 모드")
            return .failure
        }
    }
    
    func checkKakaoLoginStatus() async -> AuthFlowResult {
        // Kakao SDK 비동기 래핑
        let (info, error) = await withCheckedContinuation { continuation in
            UserApi.shared.accessTokenInfo { info, error in
                continuation.resume(returning: (info, error))
            }
        }
        
        if let error = error {
            debugPrint("🟡❌ [AutoLoginUseCase] 카카오 토큰 확인 실패: \(error.localizedDescription)")
            return handleKakaoLoginFallback(error: error)
        }
        
        if info != nil {
            debugPrint("🟡✅ [AutoLoginUseCase] 카카오 토큰 유효 - 자동 로그인 성공")
            return .success
        } else {
            debugPrint("🟡⚠️ [AutoLoginUseCase] 카카오 토큰 정보 없음 - 게스트 모드")
            return .failure
        }
    }
    
    func handleAppleLoginFallback(error: Error) -> AuthFlowResult {
        debugPrint("🍏🔄 [AutoLoginUseCase] Apple 로그인 fallback 처리")
        
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            debugPrint("🍏🌐 [AutoLoginUseCase] 네트워크 오류로 판단 - 기존 서버 토큰으로 시도")
            
            if let accessToken = KeyChainModule.read(key: .accessToken),
               !accessToken.isEmpty {
                debugPrint("🍏💾 [AutoLoginUseCase] 기존 서버 토큰 발견 - 자동 로그인 성공 처리")
                return .success
            } else {
                debugPrint("🍏⚠️ [AutoLoginUseCase] 기존 서버 토큰 없음 - 게스트 모드")
                return .failure
            }
        } else {
            debugPrint("🍏🧹 [AutoLoginUseCase] Apple 인증 오류 - 토큰 정리 후 게스트 모드")
            cleanupAppleTokens()
            return .failure
        }
    }
    
    func handleKakaoLoginFallback(error: Error) -> AuthFlowResult {
        debugPrint("🟡🔄 [AutoLoginUseCase] 카카오 로그인 fallback 처리")
        
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            debugPrint("🟡🌐 [AutoLoginUseCase] 네트워크 오류로 판단 - 기존 서버 토큰으로 시도")
            
            if let accessToken = KeyChainModule.read(key: .accessToken),
               !accessToken.isEmpty {
                debugPrint("🟡💾 [AutoLoginUseCase] 기존 서버 토큰 발견 - 자동 로그인 성공 처리")
                return .success
            } else {
                debugPrint("🟡⚠️ [AutoLoginUseCase] 기존 서버 토큰 없음 - 게스트 모드")
                return .failure
            }
        } else {
            debugPrint("🟡🧹 [AutoLoginUseCase] 카카오 인증 오류 - 토큰 정리 후 게스트 모드")
            cleanupKakaoTokens()
            return .failure
        }
    }
    
    func cleanupAppleTokens() {
        debugPrint("🍏🧹 [AutoLoginUseCase] Apple 토큰 정리 시작")
        KeyChainModule.delete(key: .appleToken)
    }
    
    func cleanupKakaoTokens() {
        debugPrint("🟡🧹 [AutoLoginUseCase] 카카오 토큰 정리 시작")
        KeyChainModule.delete(key: .kakaoToken)
    }
}
