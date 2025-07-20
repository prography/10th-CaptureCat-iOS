//
//  AuthenticatedView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/16/25.
//

import SwiftUI

struct AuthenticatedView: View {
    @StateObject private var authViewModel: AuthViewModel = AuthViewModel()
    
    var body: some View {
//        if authViewModel.authenticationState == .start {
//            RouterView {
//                StartGetScreenshotView()
//            }
//            .environmentObject(authViewModel)
//        } else {
            RouterView {
                TabContainerView()
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
            }
            .environmentObject(authViewModel)
//        }
    }
}
