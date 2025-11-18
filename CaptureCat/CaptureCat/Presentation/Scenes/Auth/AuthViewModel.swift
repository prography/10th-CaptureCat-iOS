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
    private let repository: ScreenshotRepository
    private let authUseCase: AuthUseCase
    
    @Published var authenticationState: AuthenticationState = .initial
    @Published var isAutoLoginInProgress: Bool = false
    @Published var recentLoginTypes: Set<LogIn> = []
    
    @Published var isLoginPresented: Bool = false
    @Published var isLogOutPresented: Bool = false
    @Published var isSignOutPresented: Bool = false
    @Published var showLogInPopUp: Bool = false
    @Published var errorToast: Bool = false
    @Published var errorMessage: String?
    @Published var withdrawSuccess: Bool = false
    
    init(networkManager: NetworkManager, repository: ScreenshotRepository) {
        self.networkManager = networkManager
        self.repository = repository
        
        self.authUseCase = AuthUseCase(
            socialManager: SocialManager(),
            authService: AuthService(networkManager: networkManager),
            sessionManager: SessionManager(),
            appDataResetter: AppDataResetter(repository: repository),
            autoLoginService: AutoLoginService()
        )
        
        setupNotificationObservers()
        updateRecentLoginTypes()
    }
    
    func checkAutoLogin() {
        isAutoLoginInProgress = true
        debugPrint("🔄 자동로그인 시작")
        
        Task {
            let result = await authUseCase.autoLogin()
            
            switch result {
            case .success:
                handleLoginSuccess()
            default:
                self.authenticationState = .initial
            }
            
            self.updateRecentLoginTypes()
            self.isAutoLoginInProgress = false
        }
    }
    
    @MainActor
    func send(action: Action) {
        let provider: SocialProvider = {
            switch action {
            case .kakaoSignIn:
                return .kakao
            case .appleSignIn:
                return .apple
            }
        }()
        
        Task {
            let result = await authUseCase.login(with: provider)
            handleLoginResult(result)
        }
    }
    
    private func handleLoginResult(_ result: AuthFlowResult) {
        switch result {
        case .success:
            handleLoginSuccess()
            updateRecentLoginTypes()
        case .needSignInPopup:
            self.authenticationState = .initial
            self.showLogInPopUp = true
        case .failure:
            self.authenticationState = .initial
            updateRecentLoginTypes()
        }
    }
    
    func logOut() {
        authUseCase.logout()
        updateRecentLoginTypes()
        self.authenticationState = .initial
//        MixpanelManager.shared.logout()
    }
    
    func withdraw(reason: String) {
//        MixpanelManager.shared.withdraw()
        Task {
            let result = await authUseCase.withdraw(reason: reason)
            
            switch result {
            case .success (_):
                // 회원 탈퇴 성공 시에만 모든 데이터 정리 작업 실행
                updateRecentLoginTypes()
                self.authenticationState = .initial
                self.withdrawSuccess = true
            case .failure:
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
            self.authenticationState = .signIn
            self.isAutoLoginInProgress = false
            self.isLoginPresented = false
            debugPrint("✅ 자동로그인 완료")
            
            // 모든 상태 업데이트가 완료된 후 notification 전송
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                debugPrint("📢 로그인 성공 notification 전송 완료")
            }
        }
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

extension AuthViewModel {
    func updateRecentLoginTypes() {
        recentLoginTypes = authUseCase.recentLoginTypes()
    }
}
