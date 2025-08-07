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
            TabContainerView(networkManager: networkManager)
        }
        .environment(tabSelection)
        .fullScreenCover(isPresented: $authViewModel.isLoginPresented) {
            NavigationStack {
                LogInView()
            }
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
        .task {
            authViewModel.checkAutoLogin()
            // 동기화 체크는 로그인 성공 후에만 수행하도록 AuthViewModel에서 처리
        }
    }
}
