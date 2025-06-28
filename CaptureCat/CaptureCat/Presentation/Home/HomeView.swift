//
//  HomeView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack {
            HStack {
                Text("캡쳐캣")
                    .CFont(.headline01Bold)
                Spacer()
                Button {
                    print("마이페이지 버튼")
                } label: {
                    Image(.accountCircle)
                }
            }
            .padding(.horizontal, 16)
            Spacer()
            Text("아직 스크린샷이 없어요")
                .CFont(.headline02Bold)
                .foregroundStyle(.text02)
                .padding(.bottom, 2)
            Text("스크린샷을 동기화해서 관리해보세요")
                .CFont(.body01Regular)
                .foregroundStyle(.text03)
            Spacer()
        }
    }
}

#Preview {
    HomeView()
}
