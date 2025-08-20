//
//  WithdrawView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI

struct WithdrawView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var authViewModel: AuthViewModel
    enum Reason: String, CaseIterable, Identifiable {
        case inconvenient
        case hardToFind
        case noNeed
        case usingOtherService
        
        var id: String {
            switch self {
            case .inconvenient:
                "캡쳐캣 사용이 불편해요"
            case .hardToFind:
                "스크린샷을 찾기 어려워요"
            case .noNeed:
                "스크린샷 관리가 필요하지 않아요"
            case .usingOtherService:
                "비슷한 서비스를 이미 사용하고 있어요"
            }
        }
        
        var localKey: LocalizedStringKey {
            switch self {
            case .inconvenient:
                "캡쳐캣 사용이 불편해요"
            case .hardToFind:
                "스크린샷을 찾기 어려워요"
            case .noNeed:
                "스크린샷 관리가 필요하지 않아요"
            case .usingOtherService:
                "비슷한 서비스를 이미 사용하고 있어요"
            }
        }
    }
//    let reasons = ["캡쳐캣 사용이 불편해요", "스크린샷을 찾기 어려워요", "스크린샷 관리가 필요하지 않아요", "비슷한 서비스를 이미 사용하고 있어요"]
    @State private var selectedReason: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CustomNavigationBar(
                title: "",
                onBack: {
                    router.pop()
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
                ForEach(Reason.allCases) { reason in
                    // 바인딩을 분리해서 컴파일러 부담 줄이기 + 라디오 동작
                    let isSelected = Binding<Bool>(
                        get: { selectedReason ?? "" == reason.id },
                        set: { on in selectedReason = on ? reason.id : nil }
                    )
                    
                    Toggle(isOn: isSelected) {
                        Text(reason.localKey)
                    }
                    .toggleStyle(RadioToggleStyle())
                    .padding(.horizontal, 16)
                }
            }
            .padding(.top, 60)
            Spacer()
            VStack(spacing: 4) {
                Button("계속") {
                    authViewModel.withdraw(reason: selectedReason ?? "")
                    router.pop()
                }
                .primaryStyle()
                Button("취소") {
                    router.pop()
                }
                .primaryStyle(backgroundColor: .gray02, foregroundColor: .text02)
            }
            .padding(.horizontal, 16)
        }
        .padding(.top)
    }
}
