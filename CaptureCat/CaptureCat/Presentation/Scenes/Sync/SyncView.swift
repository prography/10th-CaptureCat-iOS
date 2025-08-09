//
//  SyncView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/3/25.
//

import SwiftUI

/// 동기화 진행 여부 확인
struct SyncView: View {
    @State private var showSync: Bool = false
    private let tabSelection = TabSelection()
    
    var networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        print("🔄 TutorialView.init(\(networkManager))")
        self.networkManager = networkManager

        if let localCount = try? SwiftDataManager.shared.fetchAllEntities().count,
           localCount != 0, (AccountStorage.shared.isGuest ?? true) != true {
            showSync = true
        } else {
            showSync = false
        }
    }
    
    var body: some View {
        VStack {
            if showSync {
                SyncProgressView()
            } else {
                TabContainerView(networkManager: networkManager)
                    .environment(tabSelection)
            }
        }
        .onAppear {
            if let localCount = try? SwiftDataManager.shared.fetchAllEntities().count,
               localCount != 0, (AccountStorage.shared.isGuest ?? true) != true {
                showSync = true
            } else {
                showSync = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .syncCompleted)) { _ in
            debugPrint("📢 SyncView: 동기화 완료 알림 수신 - TabContainerView로 전환")
            showSync = false
        }
    }
}
