//
//  SyncCompletedView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/25/25.
//

import SwiftUI

struct SyncCompletedView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let syncResult: SyncResult
    @State private var showDetailResults = false
    @State private var scaleEffect: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 40) {
            // 결과에 따른 이미지와 애니메이션
            Text("모든 스크린샷 동기화 완료!")
                .CFont(.headline01Bold)
            Text("이제 모든 디바이스에서 저장하신\n스크린샷을 관리할 수 있어요.")
                .multilineTextAlignment(.center)
                .CFont(.body01Regular)
            Image(.complete)
            Spacer()
            
            // 계속하기 버튼
            VStack(spacing: 12) {
                Button("다음") {
                    debugPrint("🚀 SyncCompletedView: 메인 화면으로 이동")
                    authViewModel.authenticationState = .signIn
                }
                .primaryStyle()
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 40)
        }
        .padding(.top, 80)
        .padding(.horizontal, 20)
        .navigationBarHidden(true)
        .onAppear {
            debugPrint("📊 SyncCompletedView 표시: 성공 \(syncResult.successCount), 실패 \(syncResult.failedCount)")
        }
    }
}

#Preview {
    // 성공 케이스
    SyncCompletedView(syncResult: SyncResult(
        totalCount: 10,
        successCount: 10,
        failedCount: 0,
        failedItems: []
    ))
    .environmentObject(AuthViewModel(service: AuthService(networkManager: NetworkManager(baseURL: BaseURLType.development.url!))))
}
