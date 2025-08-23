//
//  AuthenticatedView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/16/25.
//

import SwiftUI

struct AuthenticatedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject private var updateViewModel: UpdateViewModel
    @Environment(\.openURL) private var openURL
    
    private let tabSelection = TabSelection()
    
    private let appStoreID = "6749074137"
    private var storeURL: URL { URL(string: "https://apps.apple.com/app/id\(appStoreID)")! }
    
    var networkManager: NetworkManager
    
    var body: some View {
        RouterView(networkManager: networkManager) {
            switch authViewModel.authenticationState {
            case .guest:
                TabContainerView(networkManager: networkManager)
            case .initial:
                LogInView()
            case .signIn:
                SyncView(networkManager: networkManager)
            }
        }
        .popUp(isPresented: $updateViewModel.showOptional,
               title: "새로운 버전 업데이트",
               message: "캡처캣이 사용성을 개선했어요.\n지금 바로 업데이트하고 편하게 사용해보세요!",
               cancelTitle: "취소",
               confirmTitle: "업데이트",
               confirmAction: { openURL(storeURL) }
        )
        .singlePopUp(
            isPresented: $updateViewModel.showForced,
            title: "새로운 버전 업데이트",
            message: "캡처캣이 사용성을 개선했어요.\n지금 바로 업데이트하고 편하게 사용해보세요!",
            cancelTitle: "업데이트하기",
            cancelAction: { openURL(storeURL) }
        )
        .environment(tabSelection)
        .task {
            await updateViewModel.checkNow()
            
            if KeyChainModule.read(key: .accessToken) != nil {
                debugPrint("🔄 AccessToken 발견 - 자동로그인 시작")
                authViewModel.checkAutoLogin()
            } else {
                debugPrint("🔄 AccessToken 없음 - 게스트 모드로 설정")
                authViewModel.authenticationState = .guest
                authViewModel.isAutoLoginInProgress = false
            }
            // 동기화 체크는 로그인 성공 후에만 수행하도록 AuthViewModel에서 처리
        }
    }
    
    private var mainPage: some View {
        SyncView(networkManager: networkManager)
    }
}
