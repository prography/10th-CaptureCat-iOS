//
//  AddTagSheet.swift
//  CaptureCat
//
//  Created by minsong kim on 7/7/25.
//

import SwiftUI

struct AddTagSheet: View {
    @Binding var tags: [String]
    @Binding var selectedTags: Set<String>
    @Binding var isPresented: Bool
    var onAddNewTag: ((String) -> Void)?
    var onDeleteTag: ((String) -> Void)?
    
    @State private var newTag: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var showError: Bool = false
    
    var body: some View {
        VStack(spacing: 28) {
            // 상단 바
            HStack {
                Text("태그 추가")
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
            .padding(.top, 28)
            
            // 입력 필드 및 에러 메시지
            VStack(alignment: .leading, spacing: 8) {
                TextField("추가할 태그를 입력해주세요", text: $newTag)
                    .CFont(.body02Regular)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .frame(height: 38)
                    .background(.gray01)
                    .cornerRadius(8)
                    .foregroundColor(.text03)
                    .textFieldStyle(.plain)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(showError ? Color.red : Color.clear, lineWidth: 1)
                    )
                
                // 에러 메시지
                if showError {
                    Text("태그는 4개까지 추가할 수 있습니다")
                        .CFont(.caption02Regular)
                        .foregroundColor(.error)
                        .padding(.leading, 16)
                }
            }
            .padding(.horizontal, 16)
            
            // 선택된 태그 안내
            VStack(spacing: 12) {
                // 이미 존재하는 태그 중 선택된 것만 보여주기
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            if selectedTags.contains(tag) {
                                Button {
                                    // 에러 상태 초기화 (태그 삭제 시)
                                    showError = false
                                    onDeleteTag?(tag)
                                } label: {
                                    Text(tag)
                                }
                                .chipStyle(isSelected: true, selectedBackground: .primary01, icon: Image(.xmark))
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
            
            if keyboardHeight != 0 {
                Button("완료") {
                    let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // 4개 제한 확인
                    if selectedTags.count >= 4 {
                        showError = true
                        // 3초 후 에러 메시지 자동 숨김
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            showError = false
                        }
                        return
                    }
                    
                    // 에러 상태 초기화
                    showError = false
                    
                    // 새 태그 추가 콜백 호출
                    if !trimmedTag.isEmpty {
                        onAddNewTag?(trimmedTag)
                    }
                    
                    // 입력 필드 초기화 및 키보드 숨김
                    newTag = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    isPresented = false
                }
                .primaryStyle(cornerRadius: 0)
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .padding(.bottom, 4)
            }
        }
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
