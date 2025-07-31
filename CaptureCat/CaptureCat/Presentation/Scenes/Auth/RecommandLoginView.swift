//
//  RecommandLoginView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import SwiftUI

struct RecommandLoginView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Button {
                viewModel.isLoginPresented = false
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.text01)
            }
            .padding(.bottom, 16)
            .padding(.top, 33)
            .padding(.leading, 16)
            
            VStack(spacing: 8) {
                Text("시작하기 전에")
                    .multilineTextAlignment(.center)
                    .CFont(.headline01Bold)
                Text("로그인하면 모든 디바이스에서 관리하고,\n갤러리에서 지워도 캡처캣에 안전하게 보관돼요.")
                    .multilineTextAlignment(.center)
                    .CFont(.body01Regular)
                
                Spacer()
                Image(.beforeStart)
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Text("로그인하기")
                }
                .primaryStyle()
                .padding(.horizontal, 16)
                Button {
                    viewModel.isLoginPresented = false
                } label: {
                    Text("나중에 하기")
                        .CFont(.caption02Regular)
                        .padding(.vertical, 8)
                        .foregroundStyle(.text03)
                }
            }
            .padding(.bottom, 60)
        }
    }
}
