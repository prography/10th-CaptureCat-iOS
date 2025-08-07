//
//  AuthViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import AuthenticationServices
import SwiftUI
import KakaoSDKAuth
import KakaoSDKUser

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
                isLoginPresented = true
            }
        }
    }
    
    @Published var isLoginPresented: Bool = false
    @Published var isLogOutPresented: Bool = false
    @Published var isSignOutPresented: Bool = false
    @Published var errorToast: Bool = false
    @Published var errorMessage: String?
    
    init(service: AuthService) {
        self.authService = service
        setupNotificationObservers()
    }
    
    func checkAutoLogin() {
        if let appleId = KeyChainModule.read(key: .appleToken),
           !appleId.isEmpty {
            checkAppleLoginStatus(appleId: appleId)
        } else {
            debugPrint("⚠️ Apple ID가 저장되어 있지 않음 - Apple 자동로그인 스킵")
            checkKakaoLoginStatus()
        }
    }
    
    private func checkAppleLoginStatus(appleId: String) {
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: appleId) { [weak self] state, error in
            DispatchQueue.main.async {
                if let error = error {
                    debugPrint("🍏❌ Apple ID 상태 확인 실패: \(error.localizedDescription)")
                    self?.handleAppleLoginFallback(error: error)
                    return
                }
                
                switch state {
                case .authorized:
                    debugPrint("🍏✅ Apple ID 인증 유효 - 자동 로그인 진행")
                    Task { await self?.handleLoginSuccess() }
                case .revoked:
                    debugPrint("🍏⚠️ Apple ID 인증 취소됨 - 토큰 정리 후 로그인 화면 표시")
                    self?.cleanupAppleTokens()
                    self?.authenticationState = .initial
                case .notFound:
                    debugPrint("🍏⚠️ Apple ID를 찾을 수 없음 - 토큰 정리 후 로그인 화면 표시")
                    self?.cleanupAppleTokens()
                    self?.authenticationState = .initial
                default:
                    debugPrint("🍏⚠️ Apple ID 상태 알 수 없음: \(state.rawValue) - 로그인 화면 표시")
                    self?.authenticationState = .initial
                }
            }
        }
    }
    
    private func checkKakaoLoginStatus() {
        UserApi.shared.accessTokenInfo { [weak self] info, error in
            DispatchQueue.main.async {
                if let error = error {
                    debugPrint("🟡❌ 카카오 토큰 확인 실패: \(error.localizedDescription)")
//                    self?.handleKakaoLoginFallback(error: error)
                    self?.authenticationState = .initial
                    return
                }
                
                if info != nil {
                    debugPrint("🟡✅ 카카오 토큰 유효 - 자동 로그인 진행")
                    self?.authenticationState = .signIn
                } else {
                    debugPrint("🟡⚠️ 카카오 토큰 정보 없음 - 로그인 화면 표시")
                    self?.authenticationState = .initial
                }
            }
        }
    }
    
    private func handleAppleLoginFallback(error: Error) {
        debugPrint("🍏🔄 Apple 로그인 fallback 처리")
        
        // 네트워크 오류인지 확인
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            debugPrint("🍏🌐 네트워크 오류로 판단 - 기존 토큰으로 시도")
            // 네트워크 오류시 기존 서버 토큰이 있으면 사용
            if let accessToken = KeyChainModule.read(key: .accessToken), !accessToken.isEmpty {
                debugPrint("🍏💾 기존 서버 토큰 발견 - 자동 로그인 시도")
                Task { await self.handleLoginSuccess() }
            } else {
                debugPrint("🍏⚠️ 기존 서버 토큰 없음 - 로그인 화면 표시")
                self.authenticationState = .initial
            }
        } else {
            debugPrint("🍏🧹 Apple 인증 오류 - 토큰 정리 후 로그인 화면 표시")
            cleanupAppleTokens()
            self.authenticationState = .initial
        }
    }
    
    private func handleKakaoLoginFallback(error: Error) {
        debugPrint("🟡🔄 카카오 로그인 fallback 처리")
        
        // 네트워크 오류인지 확인
        let nsError = error as NSError
        if nsError.domain == NSURLErrorDomain {
            debugPrint("🟡🌐 네트워크 오류로 판단 - 기존 토큰으로 시도")
            // 네트워크 오류시 기존 서버 토큰이 있으면 사용
            if let accessToken = KeyChainModule.read(key: .accessToken), !accessToken.isEmpty {
                debugPrint("🟡💾 기존 서버 토큰 발견 - 자동 로그인 시도")
                self.authenticationState = .signIn
            } else {
                debugPrint("🟡⚠️ 기존 서버 토큰 없음 - 로그인 화면 표시")
                self.authenticationState = .initial
            }
        } else {
            debugPrint("🟡🧹 카카오 인증 오류 - 토큰 정리 후 로그인 화면 표시")
            cleanupKakaoTokens()
            self.authenticationState = .initial
            self.isLoginPresented = true
        }
    }
    
    private func cleanupAppleTokens() {
        debugPrint("🍏🧹 Apple 토큰 정리 시작")
        KeyChainModule.delete(key: .appleToken)
    }
    
    private func cleanupKakaoTokens() {
        debugPrint("🟡🧹 카카오 토큰 정리 시작")
        KeyChainModule.delete(key: .kakaoToken)
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
                    let kakaoSignIn = await authService.login(
                        social: "kakao",
                        idToken: token.idToken,
                        authToken: token.authToken,
                        nickname: nil
                    )
                    
                    switch kakaoSignIn {
                    case .success(let success):
                        nickname = success.data.nickname
                        KeyChainModule.create(key: .kakaoToken, data: "true")
                        KeyChainModule.create(key: .didStarted, data: "\(success.data.tutorialCompleted)")
                        await handleLoginSuccess()
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
                    let appleSignIn = await authService.login(
                        social: "apple",
                        idToken: nil,
                        authToken: token.0,
                        nickname: token.1
                    )
                    
                    switch appleSignIn {
                    case .success(let success):
                        nickname = success.data.nickname
                        KeyChainModule.create(key: .didStarted, data: "\(success.data.tutorialCompleted)")
                        await handleLoginSuccess()
                    case .failure(let failure):
                        debugPrint("🔴🍎 apple sign in 함수 실패 \(failure.localizedDescription)🔴🍎")
                    }
                case .failure(let failure):
                    debugPrint("🔴🍎🔴 애플 토큰 실패 \(failure.localizedDescription) 🔴🍎🔴")
                }
            }
        }
    }
    
    func logOut() {
        safelyCleanupAllTokens()
        clearAllCacheData()
        self.authenticationState = .initial
    }
    
    func withdraw() {
        KeyChainModule.delete(key: .didStarted)
        Task {
            let result = await authService.withdraw()
            
            switch result {
            case .success (_):
                safelyCleanupAllTokens()
                clearAllCacheData()
                self.authenticationState = .initial
            case .failure (let error):
                self.errorMessage = "탈퇴에 실패했어요! 다시 시도해주세요."
                self.errorToast = true
            }
        }
    }
    
    // MARK: - 동기화 관련 메서드
    
    /// 로그인 성공 시 동기화 로직 처리
    private func handleLoginSuccess() async {
        // 토큰 저장이 완전히 완료될 때까지 잠시 대기
        await waitForTokenSaved()
        self.authenticationState = .signIn
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
    
    /// 모든 토큰을 안전하게 정리 (연쇄 삭제 방지)
    private func safelyCleanupAllTokens() {
        debugPrint("🧹 모든 토큰 안전 정리 시작")
        
        KeyChainModule.delete(key: .accessToken)
        KeyChainModule.delete(key: .refreshToken)
        KeyChainModule.delete(key: .appleToken)
        KeyChainModule.delete(key: .kakaoToken)
        AccountStorage.shared.safeReset()
        safelyCleanupUserDefaults()
        
        debugPrint("🧹 모든 토큰 및 데이터 안전 정리 완료")
    }
    
    /// UserDefaults를 안전하게 정리 (에러 무시)
    private func safelyCleanupUserDefaults() {
        debugPrint("🧹 UserDefaults 안전 정리 시작")
        UserDefaults.standard.removeObject(forKey: LocalUserKeys.selectedTopics.rawValue)
        UserDefaults.standard.synchronize()
        debugPrint("🧹 UserDefaults 안전 정리 완료")
    }
    
    /// 모든 캐시 데이터 정리 (로그아웃/회원탈퇴 시 사용)
    private func clearAllCacheData() {
        debugPrint("🧹 모든 캐시 데이터 정리 시작")
        
        // 1. 메모리 캐시 클리어 (InMemoryScreenshotCache)
        ScreenshotRepository.shared.clearMemoryCache()
        
        // 2. 모든 이미지 캐시 클리어 (서버 + 로컬)
        PhotoLoader.shared.clearAllCache()
        
        // 3. SwiftData 로컬 데이터베이스 정리
        do {
            try SwiftDataManager.shared.deleteAllScreenshots()
            debugPrint("✅ SwiftData 로컬 데이터 정리 완료")
        } catch {
            debugPrint("⚠️ SwiftData 로컬 데이터 정리 실패: \(error.localizedDescription)")
        }
        
        debugPrint("🧹 모든 캐시 데이터 정리 완료")
    }
    
    // MARK: - Notification Observers
    
    /// NotificationCenter 관찰자 설정
    private func setupNotificationObservers() {
        // 토큰 갱신 실패 알림 관찰
        NotificationCenter.default.addObserver(
            forName: .tokenRefreshFailed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleTokenRefreshFailure()
        }
    }
    
    /// 토큰 갱신 실패 처리
    private func handleTokenRefreshFailure() {
        debugPrint("🔴📢 토큰 갱신 실패 알림 수신 - 로그인 화면으로 이동")
        
        // 현재 상태가 이미 initial이 아닌 경우에만 처리 (무한 루프 방지)
        guard authenticationState != .initial else {
            debugPrint("⚠️ 이미 로그인 화면 상태이므로 처리 스킵")
            return
        }
        
        // 모든 캐시 데이터 정리
        clearAllCacheData()
        
        // 로그인 화면 표시
        self.authenticationState = .initial
        
        debugPrint("✅ 토큰 갱신 실패로 인한 로그인 화면 전환 완료")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
