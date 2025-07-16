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
        VStack {
            switch authViewModel.authenticationState {
            case .initial:
                LogInView(viewModel: authViewModel)
            case .splash:
                Text("Splash")
            case .signIn:
                RouterView {
                    TabContainerView()
                }
            case .start:
                RouterView {
                    StartGetScreenshotView()
                }
            case .guest:
                RecommandLoginView(viewModel: authViewModel)
            }
        }
    }
    
}
