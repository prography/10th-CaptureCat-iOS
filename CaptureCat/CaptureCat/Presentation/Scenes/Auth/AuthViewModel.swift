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
    private let networkManager: NetworkManager
    private let authService: AuthService
    private let repository: ScreenshotRepository
    
    @Published var authenticationState: AuthenticationState = .initial
    @Published var isAutoLoginInProgress: Bool = false
    
    @Published var isLoginPresented: Bool = false
    @Published var isLogOutPresented: Bool = false
    @Published var isSignOutPresented: Bool = false
    @Published var errorToast: Bool = false
    @Published var errorMessage: String?
    
    init(networkManager: NetworkManager, repository: ScreenshotRepository) {
        self.networkManager = networkManager
        self.authService = AuthService(networkManager: networkManager)
        self.repository = repository
        setupNotificationObservers()
    }
    
    func checkAutoLogin() {
        isAutoLoginInProgress = true
        debugPrint("🔄 자동로그인 시작")
        
        // 병렬로 토큰 체크하여 속도 최적화
        let hasAppleToken = KeyChainModule.read(key: .appleToken)?.isEmpty == false
        let hasKakaoToken = KeyChainModule.read(key: .kakaoToken)?.isEmpty == false
        
        if hasAppleToken {
            debugPrint("🍏 Apple 토큰 발견 - Apple 자동로그인 시도")
            if let appleId = KeyChainModule.read(key: .appleToken) {
                checkAppleLoginStatus(appleId: appleId)
            }
        } else if hasKakaoToken {
            debugPrint("🟡 카카오 토큰 발견 - 카카오 자동로그인 시도")
            checkKakaoLoginStatus()
        } else {
            debugPrint("⚠️ 저장된 토큰 없음 - 게스트 모드로 전환")
            DispatchQueue.main.async {
                self.authenticationState = .initial
                self.isAutoLoginInProgress = false
            }
        }
    }
    
    private func checkAppleLoginStatus(appleId: String) {
        let provider = ASAuthorizationAppleIDProvider()
        
        // 타임아웃 설정 (3초 후 카카오 fallback)
        let timeoutTask = DispatchWorkItem { [weak self] in
            debugPrint("⏰ Apple ID 상태 확인 타임아웃 - 카카오 로그인으로 fallback")
            self?.checkKakaoLoginStatus()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: timeoutTask)
        
        provider.getCredentialState(forUserID: appleId) { [weak self] state, error in
            // 타임아웃 작업 취소
            timeoutTask.cancel()
            DispatchQueue.main.async {
                if let error = error {
                    debugPrint("🍏❌ Apple ID 상태 확인 실패: \(error.localizedDescription)")
                    self?.handleAppleLoginFallback(error: error)
                    return
                }
                
                switch state {
                case .authorized:
                    debugPrint("🍏✅ Apple ID 인증 유효 - 자동 로그인 진행")
                    self?.handleLoginSuccess()
                case .revoked:
                    debugPrint("🍏⚠️ Apple ID 인증 취소됨 - 토큰 정리 후 게스트 모드로 전환")
                    self?.cleanupAppleTokens()
                    self?.authenticationState = .initial
                    self?.isAutoLoginInProgress = false
                case .notFound:
                    debugPrint("🍏⚠️ Apple ID를 찾을 수 없음 - 토큰 정리 후 게스트 모드로 전환")
                    self?.cleanupAppleTokens()
                    self?.authenticationState = .initial
                    self?.isAutoLoginInProgress = false
                default:
                    debugPrint("🍏⚠️ Apple ID 상태 알 수 없음: \(state.rawValue) - 게스트 모드로 전환")
                    self?.authenticationState = .initial
                    self?.isAutoLoginInProgress = false
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
                    self?.isAutoLoginInProgress = false
                    return
                }
                
                if info != nil {
                    debugPrint("🟡✅ 카카오 토큰 유효 - 자동 로그인 진행")
                    self?.handleLoginSuccess()
                } else {
                    debugPrint("🟡⚠️ 카카오 토큰 정보 없음 - 로그인 화면 표시")
                    self?.authenticationState = .initial
                    self?.isAutoLoginInProgress = false
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
                self.handleLoginSuccess()
            } else {
                debugPrint("🍏⚠️ 기존 서버 토큰 없음 - 로그인 화면 표시")
                self.authenticationState = .initial
                self.isAutoLoginInProgress = false
            }
        } else {
            debugPrint("🍏🧹 Apple 인증 오류 - 토큰 정리 후 로그인 화면 표시")
            cleanupAppleTokens()
            self.authenticationState = .initial
            self.isAutoLoginInProgress = false
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
                self.handleLoginSuccess()
            } else {
                debugPrint("🟡⚠️ 기존 서버 토큰 없음 - 로그인 화면 표시")
                self.authenticationState = .initial
            }
        } else {
            debugPrint("🟡🧹 카카오 인증 오류 - 토큰 정리 후 로그인 화면 표시")
            cleanupKakaoTokens()
            self.authenticationState = .initial
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
                        KeyChainModule.create(key: .kakaoToken, data: "true")
                        handleLoginSuccess(/*isTutorial: success.data.tutorialCompleted*/)
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
                        handleLoginSuccess()
                    case .failure(let failure):
                        self.authenticationState = .initial
                        debugPrint("🔴🍎 apple sign in 함수 실패 \(failure.localizedDescription)🔴🍎")
                    }
                case .failure(let failure):
                    self.authenticationState = .initial
                    debugPrint("🔴🍎🔴 애플 토큰 실패 \(failure.localizedDescription) 🔴🍎🔴")
                }
            }
        }
    }
    
    func logOut() {
        safelyCleanupAllTokens()
        clearAllCacheData()
        DispatchQueue.main.async {
            self.authenticationState = .initial
        }
//        MixpanelManager.shared.logout()
    }
    
    func withdraw(reason: String) {
        KeyChainModule.delete(key: .didStarted)
//        MixpanelManager.shared.withdraw()
        Task {
            let result = await authService.withdraw(reason: reason)
            
            switch result {
            case .success (_):
                safelyCleanupAllTokens()
                clearAllCacheData()
                safelyCleanupUserDefaults()
                DispatchQueue.main.async {
                    self.authenticationState = .initial
                }
            case .failure (let error):
                self.errorMessage = "탈퇴에 실패했어요! 다시 시도해주세요."
                self.errorToast = true
            }
        }
    }

    private func handleLoginSuccess(/*isTutorial: Bool*/) {
//        if isTutorial == false {
//            MixpanelManager.shared.signIn(userId: "")
//        }
        
        debugPrint("🔄 handleLoginSuccess 호출됨")
        DispatchQueue.main.async {
            debugPrint("🔄 authenticationState 변경 전: \(self.authenticationState)")
            self.authenticationState = .signIn
            self.isAutoLoginInProgress = false
            debugPrint("🔄 authenticationState 변경 후: \(self.authenticationState)")
            self.isLoginPresented = false
            debugPrint("🔄 isLoginPresented 변경: \(self.isLoginPresented)")
            debugPrint("✅ 자동로그인 완료")
            
            // 모든 상태 업데이트가 완료된 후 notification 전송
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                NotificationCenter.default.post(name: .loginSuccessCompleted, object: nil)
                debugPrint("📢 로그인 성공 notification 전송 완료")
            }
        }
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
        repository.clearMemoryCache()
        
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
        DispatchQueue.main.async {
            self.authenticationState = .initial
        }
        
        debugPrint("✅ 토큰 갱신 실패로 인한 로그인 화면 전환 완료")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension AuthViewModel {
    func getUserInfo() async -> Result<LogInResponseDTO, Error> {
        await UserService(networkManager: networkManager).userInfo()
    }
}
