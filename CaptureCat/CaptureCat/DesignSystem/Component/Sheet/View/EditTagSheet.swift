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
    @Binding var sheetHeight: CGFloat
    @Binding var errorMessage: String?
    @Binding var showError: Bool
    var onAddNewTag: ((String) -> Void)?
    
    @State private var newTag: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var contentSize: CGSize = .zero
    
    var dynamicHeight: CGFloat {
        // contentSize가 아직 측정되지 않았다면 기본값 사용
        guard contentSize != .zero else {
            return 180
        }
        
        let baseHeight = contentSize.height + 56 // 상하 패딩 고려
        let minHeight: CGFloat = 180
        let maxHeight = UIScreen.main.bounds.height * 0.9
        
        return max(minHeight, min(baseHeight, maxHeight))
    }
    
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
            VStack(alignment: .leading, spacing: 4) {
                TextField(tag.name, text: $newTag)
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
                
                // 에러 메시지 표시
                if showError, let errorMessage = errorMessage {
                    Text(errorMessage)
                        .CFont(.caption02Regular)
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .padding(.horizontal, 16)
            .animation(.easeInOut(duration: 0.2), value: showError)
            
//            if keyboardHeight != 0 {
                Button("완료") {
                    let trimmedTag = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // 새 태그 추가 콜백 호출
                    if !trimmedTag.isEmpty {
                        onAddNewTag?(trimmedTag)
                        
                        // 에러가 없으면 0.1초 후 시트 닫기 (에러 상태 업데이트 대기)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            if !showError {
                                isPresented = false
                            }
                        }
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
        .readSize { size in
            contentSize = size
                sheetHeight = dynamicHeight
        }
        .onAppear {
            // 초기 높이 설정
            sheetHeight = dynamicHeight
            // 키보드 notification 감지 시작
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                    sheetHeight = dynamicHeight
                }
            }
            
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                keyboardHeight = 0
                sheetHeight = dynamicHeight
            }
        }
        .onDisappear {
            // 메모리 누수 방지를 위해 notification observer 제거
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }
}
