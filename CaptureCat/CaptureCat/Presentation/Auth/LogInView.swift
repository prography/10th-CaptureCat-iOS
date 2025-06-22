//
//  LogInView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/12/25.
//

import SwiftUI

struct LogInView: View {
    var body: some View {
        VStack {
            HStack {
                Spacer()
                Button("나중에 하기") {
                    print("guest")
                }
            }
            Spacer()
            ForEach(LogIn.allCases, id:\.self) { type in
                LoginButton(type: type)
                    .onTapGesture {
                        switch type {
                        case .apple:
//                            viewModel.send(type: .apple)
                            print("apple")
                        case .kakao:
//                            viewModel.send(type: .kakao)
                            print("kakao")
                        }
                    }
            }
        }
        .padding(EdgeInsets(top: 0, leading: 12, bottom: 20, trailing: 12))
    }
}

#Preview {
    LogInView()
}
