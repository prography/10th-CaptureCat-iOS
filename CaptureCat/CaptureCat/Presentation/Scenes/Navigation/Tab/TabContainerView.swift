//
//  TabContainerView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI
import Combine

struct TabContainerView: View {
    @Environment(TabSelection.self) private var tabs
    @State private var isKeyboardVisible: Bool = false
    @State private var showTutorial: Bool = false
    
    private var networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if showTutorial {
                let viewModel = SelectMainTagViewModel(networkManager: networkManager)
                SelectMainTagView(viewModel: viewModel)
            } else {
                // 1) 탭별 화면 분기
                switch tabs.current {
                case .temporaryStorage:
                    let viewModel = StorageViewModel(networkManager: networkManager)
                    StorageView(viewModel: viewModel)
                case .home:
                    HomeView()
                case .search:
                    let viewModel = SearchViewModel(networkManager: networkManager)
                    SearchView(viewModel: viewModel)
                }
                
                // 2) 화면 아래에 탭 바 - 키보드 상태에 따라 조건부 표시
                if !isKeyboardVisible {
                    CustomTabView(
                        selectedTab: Binding(
                            get: { tabs.current },
                            set: { tabs.current = $0 }
                        )
                    )
                }
            }
        }
        .onAppear {
            if KeyChainModule.read(key: .didStarted) == "true" {
                Task {
                    await TutorialService(networkManager: networkManager).turorialComplete()
                }
                showTutorial = false
            } else {
                showTutorial = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }
}

import Observation

enum Tab: Hashable {
    case temporaryStorage
    case home
    case search
}

@Observable
@MainActor
final class TabSelection {
    var current: Tab = .home
    // 필요하면 helper
    func go(_ tab: Tab) { current = tab }
}
