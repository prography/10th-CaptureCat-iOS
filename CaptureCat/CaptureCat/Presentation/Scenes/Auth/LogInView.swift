//
//  LogInView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/12/25.
//

import AuthenticationServices
import SwiftUI

struct LogInView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var showTerms: Bool = false
    @State private var showPersonal: Bool = false
    @State private var pushGuest: Bool = false
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    pushGuest = true
                } label: {
                    Text("나중에 하기")
                        .CFont(.body02Regular)
                        .foregroundStyle(.text03)
                        .underline(true, pattern: .solid)
                }
                .padding(.trailing, 16)
            }
            .padding(.top, 33)
            Spacer()
            Image(.logInLogo)
            Spacer()
            ForEach(LogIn.allCases, id: \.self) { type in
                LoginButton(type: type)
                    .onTapGesture {
                        switch type {
                        case .apple:
                            viewModel.send(action: .appleSignIn)
                        case .kakao:
                            viewModel.send(action: .kakaoSignIn)
                        }
                    }
            }
            VStack(spacing: 4) {
                Text("가입하면 캡쳐캣의")
                    .CFont(.caption02Regular)
                    .foregroundStyle(.text03)
                HStack(spacing: 2) {
                    Button {
                        showTerms = true
                    } label: {
                        Text("이용약관")
                            .CFont(.caption02Regular)
                            .foregroundStyle(.text03)
                            .underline(true, pattern: .solid)
                    }
                    Text(" 및 ")
                        .CFont(.caption02Regular)
                        .foregroundStyle(.text03)
                    Button {
                        showTerms = true
                    } label: {
                        Text("개인정보 처리방침")
                            .CFont(.caption02Regular)
                            .foregroundStyle(.text03)
                            .underline(true, pattern: .solid)
                    }
                    Text("에 동의하게 됩니다.")
                        .CFont(.caption02Regular)
                        .foregroundStyle(.text03)
                }
            }
            .padding(.top, 24)
        }
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 20, trailing: 12))
        .sheet(isPresented: $showPersonal, content: {
            SafariView(url: URL(string: WebLink.personal.url)!)
        })
        .sheet(isPresented: $showTerms, content: {
            SafariView(url: URL(string: WebLink.terms.url)!)
        })
        .navigationDestination(isPresented: $pushGuest) {
            RecommandLoginView()
                .navigationBarBackButtonHidden()
                .toolbar(.hidden, for: .navigationBar)
        }
    }
}
