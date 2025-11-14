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
    
    var title: LocalizedStringKey {
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
    
    var value: String {
        switch self {
        case .kakao:
            "kakao"
        case .apple:
            "spple"
        }
    }
}

struct LoginButton: View {
    let type: LogIn
    let recentLoginTypes: Set<LogIn>
    
    init(type: LogIn, recentLoginTypes: Set<LogIn>) {
        self.type = type
        self.recentLoginTypes = recentLoginTypes
    }
    
    private var isRecent: Bool {
        recentLoginTypes.contains(type)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
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
            
            if isRecent {
                recentComment
                    .offset(x: -16, y: -8)
            }
        }
    }
    
    private var recentComment: some View {
        VStack(alignment: .center, spacing: 0) {
            Text("최근 로그인")
                .CFont(.caption02Regular)
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.primary01)
                )
            
            Image(systemName: "arrowtriangle.down.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 10, height: 10)
                .foregroundStyle(.primary01)
                .offset(y: -4)
        }
    }
}

#Preview {
    LoginButton(type: .kakao, recentLoginTypes: [.kakao])
}
