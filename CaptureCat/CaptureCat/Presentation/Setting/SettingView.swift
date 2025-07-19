//
//  SettingView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/17/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var router: Router
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            CustomNavigationBar(
                title: "설정",
                onBack: { router.pop() },
                actionTitle: nil,
                onAction: nil,
                isSaveEnabled: false
            )
            if AccountStorage.shared.isGuest == true {
                guestCard
                    .background(Color(.gray02))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
            } else {
                idCard
                    .background(Color(.gray02))
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
            }
            
            serviceSection
            helpSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top)
    }
    
    private var guestCard: some View {
        VStack(spacing: 12) {
            Text("현재 게스트 모드로 사용하고 있어요")
                .CFont(.subhead01Bold)
                .foregroundColor(.text01)
            
            Button(action: {
                // 로그인 액션
            }) {
                Text("로그인하기")
                    .frame(maxWidth: .infinity)
            }
            .primaryStyle()
        }
        .padding(24)
    }
    
    private var idCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("캐치님")
                .CFont(.subhead01Bold)
                .foregroundColor(.text01)
                .padding(24)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var serviceSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("서비스 정보")
                    .CFont(.body02Regular)
                    .foregroundStyle(Color.text02)
                    .backgroundStyle(Color.gray02)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray02)
            
            Button {
                debugPrint("정보")
            } label : {
                Text("개인정보 처리 방침")
                    .CFont(.body01Regular)
                    .foregroundStyle(Color.text01)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }
            
            Button {
                debugPrint("정보")
            } label : {
                Text("서비스 이용약관")
                    .CFont(.body01Regular)
                    .foregroundStyle(Color.text01)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }
            
            Button {
                debugPrint("정보")
            } label : {
                Text("버전 정보")
                    .CFont(.body01Regular)
                    .foregroundStyle(Color.text01)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }
        }
    }
    
    private var helpSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("도움말")
                    .CFont(.body02Regular)
                    .foregroundStyle(Color.text02)
                    .backgroundStyle(Color.gray02)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray02)
            
            Button {
                debugPrint("정보")
            } label : {
                Text("서비스 이용방법")
                    .CFont(.body01Regular)
                    .foregroundStyle(Color.text01)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }
            
            if AccountStorage.shared.isGuest == true {
                Button {
                    debugPrint("정보")
                } label : {
                    Text("초기화")
                        .CFont(.body01Regular)
                        .foregroundStyle(Color.text01)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
            } else {
                Button {
                    debugPrint("정보")
                } label : {
                    Text("로그아웃")
                        .CFont(.body01Regular)
                        .foregroundStyle(Color.text01)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
                Button {
                    debugPrint("정보")
                } label : {
                    Text("회원 탈퇴")
                        .CFont(.body02Regular)
                        .foregroundStyle(Color.text01)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
