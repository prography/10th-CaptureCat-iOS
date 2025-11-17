//
//  SocialService.swift
//  CaptureCat
//
//  Created by minsong kim on 7/17/25.
//

import Foundation
import KakaoSDKCommon
import KakaoSDKAuth
import KakaoSDKUser

struct SocialManager {
    func kakaoLogin() async -> Result<(authToken: String?, idToken: String), NetworkError> {
        let result = await kakaoSignIn()
        
        switch result {
        case .success(let success):
            AccountStorage.shared.kakaoToken = success.1
            return .success(success)
        case .failure(let failure):
            debugPrint("카카오 토큰 가져오기 실패 \(failure.localizedDescription)")
            return .failure(NetworkError.badRequest)
        }
    }
    
    func appleLogin() async -> Result<(String, String), NetworkError> {
        let result = await appleSignIn()
        
        switch result {
        case .success(let success):
            AccountStorage.shared.appleToken = success.token
            return .success(success)
        case .failure(let failure):
            debugPrint("애플 토큰 가져오기 실패 \(failure.localizedDescription)")
            return .failure(NetworkError.badRequest)
        }
    }
}

extension SocialManager {
    
    @MainActor
    func kakaoSignIn() async -> Result<(String?, String), NetworkError> {
        let result = await trySignInWithKakoa()
        
        guard let idToken = result.1 else {
            return .failure(.badRequest)
        }
        
        if let accessToken = result.0 {
            return .success((accessToken, idToken))
        }
        
        return .success((nil, idToken))
    }
    
    func appleSignIn() async -> Result<(token: String, nickname: String), NetworkError> {
        let appleLoginManager = AppleLoginManager()
        
        do {
            let (token, nickname) = try await appleLoginManager.login()
            debugPrint("🟢🍏🟢 애플 로그인 시도 성공 🟢🍏🟢")
            return .success((token, nickname))
        } catch {
            debugPrint("🔴🍎🔴 애플 로그인 시도 실패 \(error.localizedDescription) 🔴🍎🔴")
            return .failure(NetworkError.badRequest)
        }
    }
}

extension SocialManager {
    @MainActor
    func trySignInWithKakoa() async -> (String?, String?) {
        do {
            if UserApi.isKakaoTalkLoginAvailable() {
                return try await withCheckedThrowingContinuation { continuation in
                    UserApi.shared.loginWithKakaoTalk { (oautoken, error) in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if let oauthToken = oautoken {
                            continuation.resume(returning: (oauthToken.accessToken, oauthToken.idToken))
                        }
                    }
                }
            } else {
                debugPrint("🟡 카카오 로그인 서비스 사용 불가 > 카카오 앱 없음 🟡")
                return try await withCheckedThrowingContinuation { continuation in
                    UserApi.shared.loginWithKakaoAccount { (oauthtoken, error) in
                        if let error = error {
                            debugPrint("🍀 error \(error.localizedDescription)")
                            continuation.resume(throwing: error)
                        } else if let oauthToken = oauthtoken {
                            continuation.resume(returning: (oauthToken.accessToken, oauthToken.idToken))
                        }
                    }
                }
            }
        } catch {
            debugPrint("🟡 카카오 로그인 서비스 완전 사용 불가 🟡")
            return (nil, nil)
        }
    }
}
