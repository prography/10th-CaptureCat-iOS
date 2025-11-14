//
//  DeletePermissionSheet.swift
//  CaptureCat
//
//  Created by minsong kim on 10/31/25.
//

import SwiftUI

struct DeletePermissionSheet: View {
    @Binding var isPresented: Bool
    var goToSetting: (() -> Void)
    var later: (() -> Void)
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.5))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            Text("업로드 된 캡처를 갤러리에서 삭제할까요?")
                .CFont(.headline02Bold)
                .foregroundStyle(.text01)
                .padding(.bottom, 8)
                .padding(.top, 24)
            
            Text("중복 이미지는 정리하고, 갤러리를 더 깔끔하게 정리할 수 있어요. 삭제 여부는 매번 선택할 수 있어요.")
                .CFont(.body02Regular)
                .foregroundStyle(.text01)
                .padding(.bottom, 8)
                .multilineTextAlignment(.center)
            
            Button {
                goToSetting()
                isPresented = false
            } label: {
                Text("삭제 허용하기")
            }
            .buttonStyle(PrimaryButtonStyle(cornerRadius: 4, backgroundColor: .primary01, foregroundColor: .white, verticalPadding: 14, fillWidth: true))
            
            Button {
                later()
                isPresented = false
            } label: {
                Text("나중에")
            }
            .buttonStyle(PrimaryButtonStyle(cornerRadius: 4, backgroundColor: .gray02, foregroundColor: .text03, verticalPadding: 14, fillWidth: true))
            .padding(.bottom, 8)
            
            Text("설정에서 언제든지 변경할 수 있어요.")
                .CFont(.caption02Regular)
                .foregroundStyle(.text03)
        }
        .padding(.bottom, 16)
        .padding(.horizontal, 16)
        .background(.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }
}
