//
//  TabContainerView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

struct TabContainerView: View {
    @State private var selectedTab: Tab = .home

    var body: some View {
        ZStack {
            // 1) 탭별 화면 분기
            Group {
                switch selectedTab {
                case .temporaryStorage:
                    StorageView()
                case .home:
                    HomeView()
                case .tag:
//                    LogInView()
                    EmptyView()
                }
            }

            // 2) 화면 아래에 탭 바
            VStack {
                Spacer()
                CustomTabView(selectedTab: $selectedTab)
            }
        }
    }
}
