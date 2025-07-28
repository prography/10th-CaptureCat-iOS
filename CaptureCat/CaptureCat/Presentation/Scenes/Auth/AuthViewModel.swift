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
            switch authenticationState {
            case .initial:
                // 처음 진입 시 로그인 화면
                activeSheet = .login
                
            case .guest:
                // 게스트 모드 진입 시 추천 로그인 화면
                activeSheet = .recommend
                
            default:
                // 그 외(튜토리얼, 메인 진입 등)는 모달 닫기
                activeSheet = nil
            }
        }
    }
    
    enum ActiveSheet: Identifiable {
      case login, recommend
      var id: ActiveSheet { self }
    }
    @Published var activeSheet: ActiveSheet?
    @Published var isStartedGetScreenshot: Bool = false
    @Published var isLogOutPresented: Bool = false
    @Published var isSignOutPresented: Bool = false
    @Published var errorToast: Bool = false
    @Published var errorMessage: String?
    @Published var syncResult: SyncResult? // 동기화 결과 저장
    
    init(service: AuthService) {
        self.authService = service
    }
    
    func checkAutoLogin() {
        // Apple 로그인 상태 체크 (안전성 강화)
        checkAppleLoginStatus()
        
        // 카카오 로그인 상태 체크 (안전성 강화)
        checkKakaoLoginStatus()
    }
    
    private func checkAppleLoginStatus() {
        // Apple ID가 저장되어 있는지 확인
        guard let appleId = KeyChainModule.read(key: .appleToken), 
              !appleId.isEmpty else {
            debugPrint("⚠️ Apple ID가 저장되어 있지 않음 - Apple 자동로그인 스킵")
            return
        }
        
        debugPrint("🍏 Apple ID 상태 확인 시작: \(appleId.prefix(10))...")
        
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
                    self?.authenticationState = .signIn
                case .revoked:
                    debugPrint("🍏⚠️ Apple ID 인증 취소됨 - 토큰 정리")
                    self?.cleanupAppleTokens()
                case .notFound:
                    debugPrint("🍏⚠️ Apple ID를 찾을 수 없음 - 토큰 정리")
                    self?.cleanupAppleTokens()
                default:
                    debugPrint("🍏⚠️ Apple ID 상태 알 수 없음: \(state.rawValue)")
                }
            }
        }
    }
    
    private func checkKakaoLoginStatus() {
        // 카카오 토큰이 있는지 확인
        guard AuthApi.hasToken() else {
            debugPrint("⚠️ 카카오 토큰이 없음 - 카카오 자동로그인 스킵")
            return
        }
        
        debugPrint("🟡 카카오 토큰 상태 확인 시작")
        
        UserApi.shared.accessTokenInfo { [weak self] info, error in
            DispatchQueue.main.async {
                if let error = error {
                    debugPrint("🟡❌ 카카오 토큰 확인 실패: \(error.localizedDescription)")
                    self?.handleKakaoLoginFallback(error: error)
                    return
                }
                
                if info != nil && KeyChainModule.read(key: .kakaoToken) == "true" {
                    debugPrint("🟡✅ 카카오 토큰 유효 - 자동 로그인 진행")
                    self?.authenticationState = .signIn
                } else {
                    debugPrint("🟡⚠️ 카카오 토큰 정보 없음")
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
                self.authenticationState = .signIn
            }
        } else {
            debugPrint("🍏🧹 Apple 인증 오류 - 토큰 정리")
            cleanupAppleTokens()
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
            }
        } else {
            debugPrint("🟡🧹 카카오 인증 오류 - 토큰 정리")
            cleanupKakaoTokens()
        }
    }
    
    private func cleanupAppleTokens() {
        debugPrint("🍏🧹 Apple 토큰 정리 시작")
        KeyChainModule.delete(key: .appleToken)
        // 서버 토큰도 Apple 로그인으로 얻은 것이라면 정리
        // 하지만 카카오 로그인 토큰일 수도 있으므로 신중하게 처리
    }
    
    private func cleanupKakaoTokens() {
        debugPrint("🟡🧹 카카오 토큰 정리 시작")
        KeyChainModule.delete(key: .kakaoToken)
        // 서버 토큰도 카카오 로그인으로 얻은 것이라면 정리
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
                        KeyChainModule.create(key: .kakaoToken, data: "true")
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
        // 안전한 토큰 정리
        safelyCleanupAllTokens()
        
        // 메모리 캐시 클리어
        ScreenshotRepository.shared.clearMemoryCache()
        
        // 서버 이미지 캐시 클리어
        PhotoLoader.shared.clearAllServerImageCache()
        
        self.authenticationState = .initial
    }
    
    func withdraw() {
        Task {
            let result = await authService.withdraw()
            
            switch result {
            case .success (_):
                // 안전한 토큰 정리 (회원탈퇴 성공 시)
                safelyCleanupAllTokens()
                ScreenshotRepository.shared.clearMemoryCache()
                
                // 서버 이미지 캐시 클리어
                PhotoLoader.shared.clearAllServerImageCache()
                
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
    
    /// 모든 토큰을 안전하게 정리 (연쇄 삭제 방지)
    private func safelyCleanupAllTokens() {
        debugPrint("🧹 모든 토큰 안전 정리 시작")
        
        // 각 토큰을 개별적으로 삭제하고 에러 무시
        do {
            debugPrint("🧹 AccessToken 삭제 시도")
            KeyChainModule.delete(key: .accessToken)
        }
        
        do {
            debugPrint("🧹 RefreshToken 삭제 시도")
            KeyChainModule.delete(key: .refreshToken)
        }
        
        do {
            debugPrint("🧹 AppleToken 삭제 시도")
            KeyChainModule.delete(key: .appleToken)
        }
        
        do {
            debugPrint("🧹 KakaoToken 삭제 시도")
            KeyChainModule.delete(key: .kakaoToken)
        }
        
        // AccountStorage도 안전하게 리셋
        do {
            debugPrint("🧹 AccountStorage 안전 리셋 시도")
            AccountStorage.shared.safeReset()
        }
        
        // UserDefaults도 안전하게 정리
        do {
            debugPrint("🧹 UserDefaults 정리 시도")
            safelyCleanupUserDefaults()
        }
        
        debugPrint("🧹 모든 토큰 및 데이터 안전 정리 완료")
    }
    
    /// UserDefaults를 안전하게 정리 (에러 무시)
    private func safelyCleanupUserDefaults() {
        debugPrint("🧹 UserDefaults 안전 정리 시작")
        
        // selectedTopics (사용자 선택 태그) 삭제
        do {
            debugPrint("🧹 selectedTopics 삭제 시도")
            UserDefaults.standard.removeObject(forKey: LocalUserKeys.selectedTopics.rawValue)
        }
        
        // 다른 UserDefaults 키가 추가될 경우를 대비한 일괄 정리
        // 앱별 도메인 전체를 정리하는 방법도 있지만, 신중하게 접근
        
        // UserDefaults 동기화 (변경사항 즉시 반영)
        do {
            debugPrint("🧹 UserDefaults 동기화 시도")
            UserDefaults.standard.synchronize()
        }
        
        debugPrint("🧹 UserDefaults 안전 정리 완료")
    }
}
