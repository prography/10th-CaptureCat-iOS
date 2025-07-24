//
//  AuthenticatedView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/16/25.
//

import SwiftUI

struct AuthenticatedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    var body: some View {
        switch authViewModel.authenticationState {
        case .start:
            RouterView(networkManager: networkManager) {
                let viewModel = SelectMainTagViewModel(networkManager: networkManager)
                SelectMainTagView(viewModel: viewModel)
            }
            
        case .syncing:  // 🆕 동기화 진행 화면
            SyncProgressView()
                .environmentObject(authViewModel)
            
        case .syncCompleted:  // 🆕 동기화 완료 화면
            if let result = authViewModel.syncResult {
                SyncCompletedView(syncResult: result)
                    .environmentObject(authViewModel)
            } else {
                // fallback - 결과가 없는 경우
                VStack {
                    Text("동기화 결과를 불러올 수 없습니다")
                        .CFont(.body01Regular)
                        .foregroundStyle(.text02)
                    
                    Button("계속하기") {
                        authViewModel.authenticationState = .signIn
                    }
                    .primaryStyle()
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
                .padding()
            }
            
        default:  // 기존 로직 (signIn, guest, initial 등)
            RouterView(networkManager: networkManager) {
                TabContainerView(networkManager: networkManager)
                    .fullScreenCover(
                        isPresented: $authViewModel.isLogInPresented,
                        onDismiss: {}
                    ) {
                        LogInView()
                    }
                    .fullScreenCover(
                        isPresented: $authViewModel.isRecommandLogIn,
                        onDismiss: {}
                    ) {
                        RecommandLoginView()
                    }
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
            }
        }
    }
}
