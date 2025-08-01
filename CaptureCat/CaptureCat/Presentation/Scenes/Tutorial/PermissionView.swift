//
//  PermissionView.swift
//  CaptureCat
//
//  Created by minsong kim on 8/1/25.
//

import SwiftUI

struct PermissionView: View {
    @EnvironmentObject var router: Router
    
    var body: some View {
        VStack {
            Text("사진 접근 허용으로 스크린샷만 쏙!")
                .CFont(.headline01Bold)
                .foregroundStyle(.text01)
                .padding(.top, 125)
                .padding(.bottom, 4)
            Text("모든 사진에 대한 접근 허용을 해도\n캡처캣은 스크린샷만 불러와요")
                .CFont(.body01Regular)
                .foregroundStyle(.text02)
                .padding(.bottom, 100)
                .multilineTextAlignment(.center)
            Image(.screenshotModel)
            Spacer()
            actionButton
        }
    }
    
    private var actionButton: some View {
        Button("다음") {
            router.push(.startGetScreenshot)
        }
        .primaryStyle()
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
