//
//  ImageDeleteSettingView.swift
//  CaptureCat
//
//  Created by minsong kim on 10/12/25.
//

import SwiftUI

struct ImageDeleteSettingView: View {
    @EnvironmentObject var router: Router
    @State private var isOn: Bool = UserDefaults.standard.deleteOriginalsAfterSave
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            navigationBar
            Divider()
                .foregroundStyle(.divider)
            HStack {
                Text("업로드 후 삭제 안내 팝업 설정")
                    .CFont(.body01Regular)
                    .foregroundStyle(.text01)
                Toggle("", isOn: $isOn)
                    .toggleStyle(.switch)
                    .tint(.primary01)
                    .onChange(of: isOn) { _, newValue in
                        UserDefaults.standard.deleteOriginalsAfterSave = newValue
                    }
            }
            .padding(.horizontal, 16)
            Text("캡처캣에 업로드가 완료되면, 갤러리에서 이미지를\n삭제할지 팝업으로 안내해요.")
                .CFont(.body02Regular)
                .foregroundStyle(.text03)
                .padding(.horizontal, 16)
            Divider()
                .foregroundStyle(.divider)
            Text("""
                · 설정 후에도 삭제는 매번 직접 선택할 수 있어요.
                · 삭제된 이미지는 ‘휴지통' 또는 ‘최근 삭제된 항목'에 30일간 보관돼요.
                """)
                .CFont(.caption02Regular)
                .foregroundStyle(.text03)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top)
    }
    
    private var navigationBar: some View {
        HStack {
            Button{
                router.pop()
                print("back")
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.text02)
            }
            
            Text("이미지 삭제 설정")
                .CFont(.headline02Bold)
                .foregroundStyle(.text02)
        }
        .padding(.horizontal, 16)
    }
}
