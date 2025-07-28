//
//  SettingView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/17/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authViewModel: AuthViewModel
    @State private var showInitPopUp: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPersonal: Bool = false
    
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
        .popUp(
            isPresented: $showInitPopUp,
            title: "초기화하면",
            message: "캡쳐캣에 쌓인 유저님의 모든 데이터가 삭제됩니다.\n그래도 초기화하시겠어요?",
            cancelTitle: "취소",
            confirmTitle: "초기화"
        ) {
            UserDefaults.standard.removeObject(forKey: LocalUserKeys.selectedTopics.rawValue)
            do {
                try SwiftDataManager.shared.deleteAllScreenshots()
                debugPrint("✅ SwiftData 초기화 완료")
            } catch {
                debugPrint("❌ SwiftData 초기화 중 에러:", error)
            }
        }
        .popUp(
            isPresented: $authViewModel.isLogOutPresented,
            title: "로그아웃하면",
            message: "스크린샷을 관리하지 못할 수 있어요.\n그래도 로그아웃하시겠어요?",
            cancelTitle: "취소",
            confirmTitle: "로그아웃"
        ) {
            authViewModel.logOut()
        }
        .popUp(
            isPresented: $authViewModel.isSignOutPresented,
            title: "회원탈퇴하면",
            message: "캡쳐캣에 쌓인 유저님의 모든 데이터가 삭제됩니다.\n그래도 회원탈퇴하시겠어요?",
            cancelTitle: "취소",
            confirmTitle: "회원탈퇴"
        ) {
            //TODO: - signOutView 화면으로 이동
            authViewModel.withdraw()
        }
        .toast(isShowing: $authViewModel.errorToast, message: authViewModel.errorMessage ?? "다시 시도해주세요")
        .sheet(isPresented: $showPersonal, content: {
            SafariView(url: URL(string: WebLink.personal.url)!)
        })
        .sheet(isPresented: $showTerms, content: {
            SafariView(url: URL(string: WebLink.terms.url)!)
        })
    }
    
    private var guestCard: some View {
        VStack(spacing: 12) {
            Text("현재 게스트 모드로 사용하고 있어요")
                .CFont(.subhead01Bold)
                .foregroundColor(.text01)
            
            Button(action: {
                authViewModel.authenticationState = .initial
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
            Text(authViewModel.nickname)
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
                showPersonal = true
            } label: {
                Text("개인정보 처리 방침")
                    .CFont(.body01Regular)
                    .foregroundStyle(Color.text01)
                    .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }
            .contentShape(Rectangle())
            
            Button {
                showTerms = true
            } label: {
                Text("서비스 이용약관")
                    .CFont(.body01Regular)
                    .foregroundStyle(Color.text01)
                    .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }
            .contentShape(Rectangle())
            
            Button {
                debugPrint("버전 정보")
            } label: {
                Text("버전 정보 \(Bundle.main.appVersion)")
                    .CFont(.body01Regular)
                    .foregroundStyle(Color.text01)
                    .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
            }
            .contentShape(Rectangle())
            .disabled(true)
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
            
            if AccountStorage.shared.isGuest == true {
                Button {
                    debugPrint("초기화")
                    withAnimation {
                        showInitPopUp = true
                    }
                } label: {
                    Text("초기화")
                        .CFont(.body01Regular)
                        .foregroundStyle(Color.text01)
                        .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
                .contentShape(Rectangle())
            } else {
                Button {
                    withAnimation {
                        authViewModel.isLogOutPresented = true
                    }
                } label: {
                    Text("로그아웃")
                        .CFont(.body01Regular)
                        .foregroundStyle(Color.text01)
                        .frame(maxWidth: .infinity, minHeight: 26, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
                .contentShape(Rectangle())
                
                Button {
                    withAnimation {
                        authViewModel.isSignOutPresented = true
                    }
                } label: {
                    Text("회원 탈퇴")
                        .CFont(.body02Regular)
                        .foregroundStyle(Color.text01).frame(maxWidth: .infinity, minHeight: 16, alignment: .leading)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                }
                .contentShape(Rectangle())
            }
        }
    }
}
