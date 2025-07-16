//
//  LogInView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/12/25.
//

import AuthenticationServices
import SwiftUI

struct LogInView: View {
    @ObservedObject var viewModel: AuthViewModel
    
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
        }
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 20, trailing: 12))
    }
}
