//
//  AuthViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import SwiftUI

class AuthViewModel: ObservableObject {
    enum Action {
        case kakaoSignIn
        case appleSignIn
    }
    
    private let socialManager: SocialManager = SocialManager()
    private let authService: AuthService = AuthService(networkManager: NetworkManager(baseURL: BaseURLType.production.url!))
    
    @Published var authenticationState: AuthenticationState = .initial
    
    @MainActor
    func send(action: Action) {
        switch action {
        case .kakaoSignIn:
            Task {
                let result = await socialManager.kakaoLogin()
                switch result {
                case .success(let token):
                    debugPrint("🟡 카카오에서 토큰 값 가져오기 성공 \(token) 🟡")
                    let kakaoSignIn = await authService.login(social: "kakao", idToken: token)
                    
                    switch kakaoSignIn {
                    case .success(let success):
//                        if let isMember = success.isMember {
                        if KeyChainModule.read(key: .didStarted) == "true" {
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
                    let appleSignIn = await authService.login(social: "apple", idToken: token)
                    
                    switch appleSignIn {
                    case .success(let success):
                        if KeyChainModule.read(key: .didStarted) == "true" {
                            debugPrint("🍏 로그인 성공 > 시작하기 완료한 회원 🍏")
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
}
