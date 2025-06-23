//
//  LogInButton.swift
//  CaptureCat
//
//  Created by minsong kim on 6/12/25.
//

import SwiftUI

enum LogIn: String, CaseIterable {
    case kakao
    case apple
    
    var backgroundColor: Color {
        switch self {
        case .kakao:
            return Color.kakao
        case .apple:
            return Color.black
        }
    }
    
    var titleColor: Color {
        switch self {
        case .kakao:
            return Color.black
        case .apple:
            return Color.white
        }
    }
    
    var title: String {
        switch self {
        case .kakao:
            "카카오로 로그인"
        case .apple:
            "Apple로 로그인"
        }
    }
    
    var type: String {
        switch self {
        case .kakao:
            "KAKAO"
        case .apple:
            "APPLE"
        }
    }
    
    var image: Image {
        switch self {
        case .kakao:
            Image(.kakao)
        case .apple:
            Image(.apple)
        }
    }
    
    var width: CGFloat {
        switch self {
        case .kakao:
            18
        case .apple:
            15
        }
    }
}

struct LoginButton: View {
    let type: LogIn
    
    init(type: LogIn) {
        self.type = type
    }
    
    var body: some View {
        HStack(spacing: 8) {
            type.image
                .resizable()
                .frame(width: type.width, height: 18)
                .padding(.leading, 16)
            Text(type.title)
                .font(.headline)
                .foregroundStyle(type.titleColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 15)
        .background(type.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

#Preview {
    LoginButton(type: .kakao)
}
