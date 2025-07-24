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
    @Published var syncResult: SyncResult? // 동기화 결과 저장
    
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
                        // 토큰 저장 완료 후 동기화 시작
                        await handleLoginSuccess(tutorialCompleted: success.data.tutorialCompleted)
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
                        // 토큰 저장 완료 후 동기화 시작
                        await handleLoginSuccess(tutorialCompleted: success.data.tutorialCompleted)
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
    
    // MARK: - 동기화 관련 메서드
    
    /// 로그인 성공 시 동기화 로직 처리
    private func handleLoginSuccess(tutorialCompleted: Bool) async {
        // 토큰 저장이 완전히 완료될 때까지 잠시 대기
        await waitForTokenSaved()
        
        if tutorialCompleted {
            // 튜토리얼 완료한 사용자
            if hasLocalData() {
                debugPrint("🔄 로그인 성공 + 로컬 데이터 존재 → 동기화 시작")
                self.authenticationState = .syncing
            } else {
                debugPrint("🔄 로그인 성공 + 로컬 데이터 없음 → 바로 메인화면")
                self.authenticationState = .signIn
            }
        } else {
            // 튜토리얼 미완료 사용자
            debugPrint("🔄 로그인 성공 + 튜토리얼 미완료 → 시작하기 화면")
            self.authenticationState = .start
        }
    }
    
    /// 토큰이 저장될 때까지 대기
    private func waitForTokenSaved() async {
        // 최대 3초까지 0.1초 간격으로 토큰 확인
        for _ in 0..<30 {
            if let accessToken = AccountStorage.shared.accessToken, !accessToken.isEmpty {
                debugPrint("✅ 토큰 저장 확인 완료: \(accessToken.prefix(20))...")
                return
            }
            debugPrint("⏳ 토큰 저장 대기 중...")
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1초 대기
        }
        debugPrint("⚠️ 토큰 저장 확인 실패 - 타임아웃")
    }
    
    /// 로컬에 동기화할 데이터가 있는지 확인
    private func hasLocalData() -> Bool {
        do {
            let localCount = try SwiftDataManager.shared.fetchAllEntities().count
            debugPrint("📱 로컬 스크린샷 개수: \(localCount)개")
            return localCount > 0
        } catch {
            debugPrint("❌ 로컬 데이터 확인 실패: \(error)")
            return false
        }
    }
}
