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
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button{
                    viewModel.guestMode()
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
            ForEach(LogIn.allCases, id:\.self) { type in
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
                HStack(spacing: 0) {
                    Button {
                        viewModel.authenticationState = .terms
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
                        viewModel.authenticationState = .personal
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
    }
}
