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
            
            // TagEditCompleted 알림 대신 홈에서 직접 새로고침을 위한 플래그 설정
            UserDefaults.standard.set(true, forKey: "needsRefreshAfterUpload")
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
