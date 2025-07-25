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
        print("🔄 AuthenticatedView.init(\(networkManager))")
        self.networkManager = networkManager
    }
    
    var body: some View {
        ZStack {
            switch authViewModel.authenticationState {
            case .start:
                RouterView(networkManager: networkManager) {
                    let viewModel = SelectMainTagViewModel(networkManager: networkManager)
                    SelectMainTagView(viewModel: viewModel)
                }
            case .syncing:
                SyncProgressView().environmentObject(authViewModel)
            case .syncCompleted:
                SyncCompletedView(syncResult: authViewModel.syncResult!).environmentObject(authViewModel)
            case .initial, .signIn, .guest:
                RouterView(networkManager: networkManager) {
                    TabContainerView(networkManager: networkManager)
                }
            }
        }
        .fullScreenCover(item: $authViewModel.activeSheet) { sheet in
          switch sheet {
            case .login: LogInView()
            case .recommend: RecommandLoginView()
          }
        }
        .transaction { transaction in
            transaction.disablesAnimations = true
        }
        .task {
            authViewModel.checkAutoLogin()
        }
    }
}
