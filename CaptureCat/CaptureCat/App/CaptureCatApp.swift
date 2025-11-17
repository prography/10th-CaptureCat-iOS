//
//  CaptureCatApp.swift
//  CaptureCat
//
//  Created by minsong kim on 6/3/25.
//

import SwiftUI
import SwiftData
import KakaoSDKAuth

@main
struct CaptureCatApp: App {
    // MARK: - App-scoped state objects
    @StateObject private var dependencies = AppDependencies()
    
    @Environment(\.scenePhase) private var scenePhase
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            Group {
                if dependencies.onBoardingViewModel.isOnBoarding {
                    OnBoardingView(viewModel: $dependencies.onBoardingViewModel)
                } else {
                    AuthenticatedView(networkManager: dependencies.networkManager)
                        .environmentObject(dependencies.screenshotRepository)
                        .environmentObject(dependencies.updateViewModel)
                        .environmentObject(dependencies.authViewModel)
                        .environmentObject(dependencies.homeViewModel)
                        .environmentObject(dependencies.searchViewModel)
                        .modelContainer(SwiftDataManager.shared.modelContainer)
                        .onOpenURL { url in
                            if AuthApi.isKakaoTalkLoginUrl(url) {
                                _ = AuthController.handleOpenUrl(url: url)
                            }
                        }
                }
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
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
    
    /// 백그라운드 진입 시 처리
    private func handleAppDidEnterBackground() {
        PhotoLoader.shared.cacheInfo()
        debugPrint("💾 백그라운드 진입 - 캐시 상태 확인 완료")
    }
    
    /// 앱 활성화 시 처리
    private func handleAppDidBecomeActive() {
        PhotoLoader.shared.cacheInfo()
        debugPrint("🚀 앱 활성화 - 캐시 상태 정상")
    }
}
