//
//  TabContainerView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

struct TabContainerView: View {
    @State private var selectedTab: Tab = .home
    
    private var networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    var body: some View {
        ZStack {
            // 1) 탭별 화면 분기
//            Group {
                switch selectedTab {
                case .temporaryStorage:
                    let viewModel = StorageViewModel(networkManager: networkManager)
                    StorageView(viewModel: viewModel)
                case .home:
                    let viewModel = HomeViewModel(networkManager: networkManager)
                    HomeView(viewModel: viewModel)
                case .search:
                    let viewModel = SearchViewModel(networkManager: networkManager)
                    SearchView(viewModel: viewModel)
                }
//            }

            // 2) 화면 아래에 탭 바
            VStack {
                Spacer()
                CustomTabView(selectedTab: $selectedTab)
            }
        }
    }
}
