//
//  CaptureCatApp.swift
//  CaptureCat
//
//  Created by minsong kim on 6/3/25.
//

import SwiftUI
import SwiftData
import KakaoSDKCommon
import KakaoSDKAuth

@main
struct CaptureCatApp: App {
    @State var onBoardingViewModel: OnBoardingViewModel = OnBoardingViewModel()
    
    init() {
        KakaoSDK.initSDK(appKey: Bundle.main.kakaoKey ?? "")
    }
    
    var body: some Scene {
        WindowGroup {
            if onBoardingViewModel.isOnBoarding {
                OnBoardingView(viewModel: $onBoardingViewModel)
            } else {
                AuthenticatedView()
                    .modelContainer(SwiftDataManager.shared.modelContainer)
                    .onOpenURL { url in
                        if (AuthApi.isKakaoTalkLoginUrl(url)) {
                            _ = AuthController.handleOpenUrl(url: url)
                        }
                    }
            }
        }
    }
}
