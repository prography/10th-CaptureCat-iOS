//
//  AuthViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import SwiftUI

@MainActor
class AuthViewModel: ObservableObject {
    enum Action {
        case kakaoSignIn
        case appleSignIn
    }
    
    private let socialManager: SocialManager = SocialManager()
    private let authService: AuthService
    var nickname: String = "캐치님"
    
    @Published var authenticationState: AuthenticationState = .initial {
        didSet {
            if authenticationState == .initial {
                isLogInPresented = true
                isRecommandLogIn = false
            } else if authenticationState == .guest {
                isLogInPresented = false
                isRecommandLogIn = true
            } else {
                isLogInPresented = false
                isRecommandLogIn = false
            }
        }
    }
    
    @Published var isLogInPresented: Bool = true
    @Published var isRecommandLogIn: Bool = false
    @Published var isStartedGetScreenshot: Bool = false
    @Published var isLogOutPresented: Bool = false
    @Published var isSignOutPresented: Bool = false
    @Published var errorToast: Bool = false
    @Published var errorMessage: String?
    
    init(service: AuthService) {
        self.authService = service
    }
    
    @MainActor
    func send(action: Action) {
        switch action {
        case .kakaoSignIn:
            Task {
                let result = await socialManager.kakaoLogin()
                switch result {
                case .success(let token):
                    debugPrint("🟡 카카오에서 토큰 값 가져오기 성공 \(token) 🟡")
                    let kakaoSignIn = await authService.login(social: "kakao", idToken: token, nickname: nil)
                    
                    switch kakaoSignIn {
                    case .success(let success):
                        nickname = success.data.nickname
                        if success.data.tutorialCompleted {
                            debugPrint("🟡 로그인 성공 > 시작하기 완료한 회원 🟡")
                            self.authenticationState = .signIn
                            return
                        } else {
                            debugPrint("🟡 로그인 함수만 성공 > 비회원 > 시작하기 필요 🟡")
                            self.authenticationState = .start
                        }
                    case .failure(let failure):
                        debugPrint("🟡🔴 카카오 로그인 완전 실패 \(failure.localizedDescription) 🟡🔴")
                        self.authenticationState = .initial
                    }
                case .failure(let failure):
                    debugPrint("🟡🔴 카카오에서 토큰 값 가져오기 실패 \(failure.localizedDescription) 🟡🔴")
                    self.authenticationState = .initial
                }
            }
            
        case .appleSignIn:
            
            Task {
                let result = await socialManager.appleLogin()
                
                switch result {
                case .success(let token):
                    let appleSignIn = await authService.login(social: "apple", idToken: token.0, nickname: token.1)
                    
                    switch appleSignIn {
                    case .success(let success):
                        nickname = success.data.nickname
                        if success.data.tutorialCompleted {
                            debugPrint("🍏 로그인 성공 > 시작하기 완료한 회원 🍏")
                            debugPrint("닉네임: \(success.data.nickname)")
                            self.authenticationState = .signIn
                            return
                        } else {
                            debugPrint("🍏🔴 로그인 함수만 성공 > 비회원 > 시작하기 진행 🍏🔴")
                            self.authenticationState = .start
                        }
                    case .failure(let failure):
                        debugPrint("🔴🍎 apple sign in 함수 실패 \(failure.localizedDescription)🔴🍎")
                    }
                case .failure(let failure):
                    debugPrint("🔴🍎🔴 애플 토큰 실패 \(failure.localizedDescription) 🔴🍎🔴")
                }
            }
        }
    }
    
    func guestMode() {
        self.authenticationState = .guest
    }
    
    func logOut() {
        KeyChainModule.delete(key: .accessToken)
        KeyChainModule.delete(key: .refreshToken)
        
        // 메모리 캐시 클리어
        ScreenshotRepository.shared.clearMemoryCache()
        
        self.authenticationState = .initial
    }
    
    func withdraw() {
        Task {
            let result = await authService.withdraw()
            
            switch result {
            case .success (_):
                KeyChainModule.delete(key: .accessToken)
                KeyChainModule.delete(key: .refreshToken)
                ScreenshotRepository.shared.clearMemoryCache()
                self.authenticationState = .initial
            case .failure (let error):
                self.errorMessage = "탈퇴에 실패했어요! 다시 시도해주세요."
                self.errorToast = true
            }
        }
    }
}
