//
//  SyncProgressView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/25/25.
//

import SwiftUI

struct SyncProgressView: View {
    @EnvironmentObject var router: Router
    @StateObject private var syncService = SyncService.shared
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            // 로고 또는 일러스트
            Image(.screenshotShadow)
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 282)
                .offset(y: animationOffset)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 2.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        animationOffset = -10
                    }
                }
            
            VStack(spacing: 16) {
                Text("모든 스크린샷을\n동기화하고 있어요")
                    .CFont(.headline01Bold)
                    .foregroundStyle(.text01)
                
                Text("Tip. 즐겨찾기를 하면 홈에서\n더 자주 볼 수 있어요.")
                    .CFont(.body01Regular)
                    .foregroundStyle(.text02)
                    .multilineTextAlignment(.center)
                // 퍼센티지 표시
                HStack {
                    Text("\(Int(syncService.syncProgress.percentage * 100))% 완료")
                        .CFont(.subhead02Bold)
                        .foregroundStyle(.primary01)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                }
                .background(.primaryLow)
            }
            
            Spacer()
        }
        .onAppear {
            startSync()
        }
        .navigationBarHidden(true)
    }
    
    private func startSync() {
        Task {
            debugPrint("🔄 SyncProgressView: 동기화 시작")
            debugPrint("🔍 현재 토큰 상태: \(AccountStorage.shared.accessToken?.prefix(20) ?? "없음")...")
            
            let result = await syncService.syncLocalScreenshotsToServer()
            
            // 동기화 완료 후 결과에 따라 다음 화면으로 전환
            await MainActor.run {
                debugPrint("✅ SyncProgressView: 동기화 완료")
                debugPrint("📊 동기화 결과: 총 \(result.totalCount)개, 성공 \(result.successCount)개, 실패 \(result.failedCount)개")
                
                router.push(.completeSync(result: result))
            }
        }
    }
}

//#Preview {
//    SyncProgressView()
//        .environmentObject(AuthViewModel(service: AuthService(networkManager: NetworkManager(baseURL: BaseURLType.development.url!))))
//}
