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
        if authViewModel.authenticationState == .start {
            RouterView(networkManager: networkManager) {
                let viewModel = SelectMainTagViewModel(networkManager: networkManager)
                SelectMainTagView(viewModel: viewModel)
            }
        } else {
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
                    .fullScreenCover(
                        isPresented: $authViewModel.isPersonalPresented,
                        onDismiss: {}
                    ) {
                        WebView(webLink: .personal)
                    }
                    .fullScreenCover(
                        isPresented: $authViewModel.isTermsPresented,
                        onDismiss: {}
                    ) {
                        WebView(webLink: .terms)
                    }
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
            }
        }
    }
}
