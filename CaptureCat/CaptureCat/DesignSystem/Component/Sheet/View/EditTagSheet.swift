//
//  EditTagSheet.swift
//  CaptureCat
//
//  Created by minsong kim on 8/22/25.
//

import SwiftUI

struct EditTagSheet: View {
    @Binding var tag: Tag
    @Binding var isPresented: Bool
    var onAddNewTag: ((String) -> Void)?
    
    @State private var newTag: String = ""
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 28) {
            // 상단 바
            HStack {
                Text("태그 수정")
                    .CFont(.headline03Bold)
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            
            // 입력 필드
            TextField(tag.name, text: $newTag)
                .CFont(.body02Regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(height: 38)
                .background(.gray01)
                .cornerRadius(8)
                .foregroundColor(.text03)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
            
//            if keyboardHeight != 0 {
                Button("완료") {
                    let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // 새 태그 추가 콜백 호출
                    if !trimmedTag.isEmpty {
                        onAddNewTag?(trimmedTag)
                    }
                    
                    // 입력 필드 초기화 및 키보드 숨김
                    newTag = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .primaryStyle(cornerRadius: keyboardHeight != 0 ? 0 : 8)
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .padding(.bottom, 8)
                .padding(.horizontal, keyboardHeight != 0 ? 0 : 16)
//            }
        }
        .padding(.top, 28)
        .onAppear {
            // 키보드 notification 감지 시작
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                keyboardHeight = 0
            }
        }
        .onDisappear {
            // 메모리 누수 방지를 위해 notification observer 제거
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
}
