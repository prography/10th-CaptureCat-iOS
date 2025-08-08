//
//  AuthenticatedView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/16/25.
//

import SwiftUI

struct AuthenticatedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    private let tabSelection = TabSelection()
    
    var networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        print("🔄 AuthenticatedView.init(\(networkManager))")
        self.networkManager = networkManager
    }
    
    var body: some View {
        RouterView(networkManager: networkManager) {
            SyncView(networkManager: networkManager)
        }
        .environment(tabSelection)
        .fullScreenCover(isPresented: Binding(
            get: { 
                let shouldShow = authViewModel.authenticationState == .initial
                debugPrint("🔍 AuthenticatedView - authenticationState: \(authViewModel.authenticationState), shouldShow: \(shouldShow)")
                return shouldShow
            },
            set: { _ in }
        )) {
            NavigationStack {
                LogInView()
            }
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
        .task {
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
        .onChange(of: authViewModel.authenticationState) { oldValue, newValue in
            debugPrint("🔄 AuthenticatedView - authenticationState 변경: \(oldValue) -> \(newValue)")
        }
    }
}
