//
//  SignOutView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI

struct SignOutView: View {
    @Environment(\.dismiss) private var dismiss
    let reasons = ["캡쳐캣을 사용하기 어려움", "개인 정보가 우려됨", "캡쳐캣이 더 이상 유용하지 않음", "이미지 파일이 안전하지 않다고 생각됨"]
    @State private var selectedReason: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CustomNavigationBar(
                title: "",
                onBack: {
                    dismiss()
                },
                actionTitle: nil,
                onAction: nil,
                isSaveEnabled: false
            )
            
            Text("삭제하기 전에 도움을 받아보세요.")
                .CFont(.headline01Bold)
                .foregroundStyle(.text01)
                .padding(.horizontal, 16)
            Text("그동안 이용해주셔서 감사합니다. 계정을 삭제하는 이유를 알려주시면 해당 문제에 관해 저희가 도움을 드릴 수 있습니다. 원치않으시는 경우 이유를 선택하지 않고 삭제를 계속 진행하실 수 있습니다.")
                .CFont(.body02Regular)
                .foregroundStyle(.text03)
                .padding(.horizontal, 16)
            
            VStack(spacing: 4) {
                ForEach(reasons, id: \.self) { reason in
                    Toggle(reason, isOn: Binding(
                        get: {selectedReason == reason},
                        set: { on in
                            if on { selectedReason = reason }
                        }
                    ))
                    .toggleStyle(RadioToggleStyle())
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 60)
            Spacer()
            VStack(spacing: 4) {
                Button("계속") {
                    //TODO: - 회원 탈퇴 구현
                    dismiss()
                }
                .primaryStyle()
                Button("취소") {
                    dismiss()
                }
                .primaryStyle(backgroundColor: .gray02, foregroundColor: .text02)
            }
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    SignOutView()
}
