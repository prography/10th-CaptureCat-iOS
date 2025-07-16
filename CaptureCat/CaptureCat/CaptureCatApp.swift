//
//  CaptureCatApp.swift
//  CaptureCat
//
//  Created by minsong kim on 6/3/25.
//

import SwiftUI

@main
struct CaptureCatApp: App {
    var body: some Scene {
        WindowGroup {
            if onBoardingViewModel.isOnBoarding {
                OnBoardingView(viewModel: $onBoardingViewModel)
            } else {
                RouterView {
                    TabContainerView()
                }
            }
        }
    }
}
