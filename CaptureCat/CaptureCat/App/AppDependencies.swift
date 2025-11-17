//
//  AppDependencies.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import UIKit

@MainActor
final class AppDependencies: ObservableObject {
    // MARK: - Core dependencies
    let networkManager: NetworkManager
    let screenshotRepository: ScreenshotRepository

    // MARK: - ViewModels
    @Published var onBoardingViewModel = OnBoardingViewModel()
    let authViewModel: AuthViewModel
    let homeViewModel: HomeViewModel
    let updateViewModel = UpdateViewModel()
    let searchViewModel: SearchViewModel

    init() {
        // 1) baseURL
        let baseURL = Bundle.main.baseURL!
        let networkManager = NetworkManager(baseURL: baseURL)
        self.networkManager = networkManager

        // 2) repository
        let repo = ScreenshotRepository(networkManager: networkManager)
        self.screenshotRepository = repo

        // 3) view models
        self.authViewModel = AuthViewModel(
            networkManager: networkManager,
            repository: repo
        )
        self.homeViewModel = HomeViewModel(
            repository: repo,
            networkManager: networkManager
        )
        self.searchViewModel = SearchViewModel(
            repository: repo,
            networkManager: networkManager
        )
    }
}
