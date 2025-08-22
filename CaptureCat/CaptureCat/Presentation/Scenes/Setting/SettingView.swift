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
    @EnvironmentObject private var updateViewModel: UpdateViewModel
    @Environment(\.openURL) private var openURL
    
    @State private var nickname: String = "캐치님"
    @State private var showInitPopUp: Bool = false
    @State private var showTerms: Bool = false
    @State private var showPersonal: Bool = false
    @State private var showChannel: Bool = false
    @State private var showUpdate: Bool = false
    
    private let appStoreID = "6749074137"
    private var storeURL: URL { URL(string: "https://apps.apple.com/app/id\(appStoreID)")! }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            CustomNavigationBar(
                title: "설정",
                onBack: { router.pop() },
                actionTitle: nil,
                onAction: nil,
                isSaveEnabled: false
            )
            
            if authViewModel.authenticationState == .guest {
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
            personalSettingSection
            serviceSection
            helpSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top)
        .task {
            let result = await authViewModel.getUserInfo()
            
            switch result {
            case .success(let response):
                nickname = response.data.nickname
            case .failure(let error):
                debugPrint(error)
            }
        }
        .popUp(isPresented: $showUpdate,
               title: "새로운 버전 업데이트",
               message: "캡처캣이 사용성을 개선했어요.\n지금 바로 업데이트하고 편하게 사용해보세요!",
               cancelTitle: "취소",
               confirmTitle: "업데이트",
               confirmAction: { openURL(storeURL) }
        )
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
            router.pop()
        }
        .popUp(
            isPresented: $authViewModel.isSignOutPresented,
            title: "회원탈퇴하면",
            message: "캡쳐캣에 쌓인 유저님의 모든 데이터가 삭제됩니다.\n그래도 회원탈퇴하시겠어요?",
            cancelTitle: "취소",
            confirmTitle: "회원탈퇴"
        ) {
            router.push(.withdraw)
        }
//        .toast(isShowing: $authViewModel.errorToast, message: authViewModel.errorMessage ?? "다시 시도해주세요")
        .sheet(isPresented: $showPersonal, content: {
            SafariView(url: URL(string: WebLink.personal.url)!)
        })
        .sheet(isPresented: $showTerms, content: {
            SafariView(url: URL(string: WebLink.terms.url)!)
        })
        .sheet(isPresented: $showChannel) {
            SafariView(url: KakaoChannelManger.safariURL!)
        }
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
            Text(nickname)
                .CFont(.subhead01Bold)
                .foregroundColor(.text01)
                .padding(24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var personalSettingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("사용자 환경 설정")
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
                router.push(.tagSetting)
            } label: {
                SettingRow(title: "태그 설정")
            }
            .contentShape(Rectangle())
        }
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
                SettingRow(title: "개인정보 처리방침")
            }
            .contentShape(Rectangle())
            
            Button {
                showTerms = true
            } label: {
                SettingRow(title: "이용 약관")
            }
            .contentShape(Rectangle())
            
            Button {
                openURL(storeURL)
            } label: {
                SettingRow(title: "앱 리뷰 남기기")
            }
            .contentShape(Rectangle())
            
            Button {
                showUpdate = true
                debugPrint("버전 정보")
            } label: {
                VStack {
                    HStack {
                        Text("버전 정보")
                            .CFont(.body01Regular)
                            .foregroundStyle(Color.text01)
                        Spacer()
                        
                        if updateViewModel.requiredVersion != Bundle.main.appVersion {
                            Text("업데이트")
                                .CFont(.body01Regular)
                                .foregroundStyle(Color.text01)
                        }
                    }
                    Text("\(Bundle.main.appVersion)")
                        .CFont(.caption02Regular)
                        .foregroundStyle(Color.text01)
                        .frame(maxWidth: .infinity, minHeight: 12, alignment: .leading)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            }
            .contentShape(Rectangle())
            .disabled(updateViewModel.requiredVersion == Bundle.main.appVersion)
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
//                KakaoChannelManger.chatChannel()
                showChannel = true
            } label: {
                SettingRow(title: "채널 문의하기")
            }
            .contentShape(Rectangle())
            
            if authViewModel.authenticationState == .guest {
                Button {
                    debugPrint("초기화")
                    KeyChainModule.delete(key: .didStarted)
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
                        .CFont(.body02Regular)
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
