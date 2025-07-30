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
            
            // 입력 필드
            TextField("추가할 태그를 입력해주세요", text: $newTag)
                .CFont(.body02Regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .frame(height: 38)
                .background(.gray01)
                .cornerRadius(8)
                .foregroundColor(.text03)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
            
            // 선택된 태그 안내
            VStack(spacing: 12) {
                HStack {
                    Text("추가된 태그")
                        .CFont(.headline03Bold)
                    Spacer()
                    Text("태그는 최대 4개까지 지정할 수 있어요")
                        .CFont(.caption02Regular)
                }
                .padding(.horizontal, 16)
                
                // 이미 존재하는 태그 중 선택된 것만 보여주기
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            if selectedTags.contains(tag) {
                                Button {
                                    // selectedTags에서 제거
//                                    selectedTags.remove(tag)
                                    // 실제 태그 삭제 콜백 호출
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
                    
                    // 새 태그 추가 콜백 호출
                    if !trimmedTag.isEmpty {
                        onAddNewTag?(trimmedTag)
                    }
                    
                    // 입력 필드 초기화 및 키보드 숨김
                    newTag = ""
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
                .primaryStyle(cornerRadius: 0)
                .disabled(newTag.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .padding(.bottom, 8)
            }
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
