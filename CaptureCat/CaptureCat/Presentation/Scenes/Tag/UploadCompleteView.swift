//
//  UploadCompleteView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import SwiftUI

struct UploadCompleteView: View {
    @Environment(TabSelection.self) private var tabs
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var router: Router
    let count: Int
    
    var body: some View {
        Text("\(count)장 정리 완료!")
            .CFont(.headline01Bold)
            .foregroundColor(.text01)
            .padding(.bottom, 16)
            .padding(.top, 150)
        Text("즐겨찾기를 한 스크린샷은\n홈에서 더 자주 만날 수 있어요.")
            .multilineTextAlignment(.center)
            .CFont(.body01Regular)
            .foregroundStyle(.text02)
            .padding(.bottom, 24)
        Image(.cleanComplete)
        Spacer()
        Button {
            router.popToRoot()
            tabs.go(.home)
            KeyChainModule.create(key: .didStarted, data: "true")
            
            // 낙관적 업데이트는 이미 TagView에서 완료되었으므로 추가 알림 불필요
            // HomeView는 자동으로 낙관적 업데이트 완료 알림을 받아서 처리함
        } label: {
            Text("다음")
        }
        .primaryStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 26)
    }
}

#Preview {
    UploadCompleteView(count: 10)
}
