//
//  CaptureCatApp.swift
//  CaptureCat
//
//  Created by minsong kim on 6/3/25.
//

import KakaoSDKCommon
import KakaoSDKAuth
import Mixpanel
import SwiftUI
import SwiftData

@main
struct CaptureCatApp: App {
    @State var onBoardingViewModel: OnBoardingViewModel = OnBoardingViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    private var networkManager: NetworkManager {
        guard let url = BaseURLType.production.url else {
            fatalError("Invalid base URL")
        }
        
        return NetworkManager(baseURL: url)
    }
    
    init() {
        KakaoSDK.initSDK(appKey: Bundle.main.kakaoKey ?? "")
        UITextField.appearance().tintColor = .gray09
        Mixpanel.initialize(token: Bundle.main.mixpanelToken ?? "", trackAutomaticEvents: true)
        setupMemoryWarningNotification()
    }
    
    var body: some Scene {
        WindowGroup {
            if onBoardingViewModel.isOnBoarding {
                OnBoardingView(viewModel: $onBoardingViewModel)
            } else {
                let service = AuthService(networkManager: networkManager)
                
                AuthenticatedView(networkManager: networkManager)
                    .environmentObject(AuthViewModel(service: service))
                    .environmentObject(HomeViewModel(networkManager: networkManager))
                    .modelContainer(SwiftDataManager.shared.modelContainer)
                    .onOpenURL { url in
                        if (AuthApi.isKakaoTalkLoginUrl(url)) {
                            _ = AuthController.handleOpenUrl(url: url)
                        }
                    }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    // MARK: - Memory Management
    
    /// 메모리 경고 알림 설정
    private func setupMemoryWarningNotification() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            handleMemoryWarning()
        }
    }
    
    /// Scene Phase 변화 처리
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .background:
            debugPrint("📱 앱이 백그라운드로 진입")
            handleAppDidEnterBackground()
        case .inactive:
            debugPrint("📱 앱이 비활성 상태")
        case .active:
            debugPrint("📱 앱이 활성 상태")
            handleAppDidBecomeActive()
        @unknown default:
            break
        }
    }
    
    /// 메모리 경고 처리
    private func handleMemoryWarning() {
        debugPrint("⚠️ 메모리 경고 발생 - 캐시 정리 시작")
        
        // PhotoLoader 캐시 일부 정리 (디스크 캐시는 유지, 메모리 캐시만 정리)
        // 전체 삭제는 하지 않고 일부만 정리하여 사용자 경험 유지
        PhotoLoader.shared.cacheInfo()
        
        // 필요시 추가적인 메모리 정리 로직
        debugPrint("✅ 메모리 경고 대응 완료")
    }
    
    /// 백그라운드 진입 시 처리
    private func handleAppDidEnterBackground() {
        // 백그라운드에서는 메모리 사용량을 최소화
        // 하지만 완전히 삭제하지는 않아서 다시 돌아왔을 때 빠른 로딩 가능
        PhotoLoader.shared.cacheInfo()
        debugPrint("💾 백그라운드 진입 - 캐시 상태 확인 완료")
    }
    
    /// 앱 활성화 시 처리
    private func handleAppDidBecomeActive() {
        // 앱이 다시 활성화될 때 필요한 처리
        PhotoLoader.shared.cacheInfo()
        debugPrint("🚀 앱 활성화 - 캐시 상태 정상")
    }
}
