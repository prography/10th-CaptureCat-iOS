//
//  TagSheet.swift
//  CaptureCat
//
//  Created by minsong kim on 10/11/25.
//

import SwiftUI

enum TagSheetMode {
    case add
    case edit
}

struct TagSheet: View {
    @Binding var mode: TagSheetMode
    @Binding var isExpanded: Bool
    @Binding var tags: [String]
    @Binding var selectedTags: Set<String>
    @Binding var isPresented: Bool
    @Binding var sheetHeight: CGFloat
    @Binding var errorMessage: String?
    @Binding var showError: Bool
    var onAddNewTag: ((String) -> Void)?
    var onDeleteTag: ((String) -> Void)?
    var onSaveTag: ((String) -> Void)?
    
    @State private var newTag: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @State private var contentSize: CGSize = .zero
    
    var dynamicHeight: CGFloat {
        // contentSize가 아직 측정되지 않았다면 기본값 사용
        guard contentSize != .zero else {
            return mode == .add ? 200 : (isExpanded ? 450 : 300)
        }
        
        let baseHeight = contentSize.height + 56 // 상하 패딩 고려
        let keyboardAdjustment = keyboardHeight > 0 ? 60 : 0 // 버튼 높이 고려
        let calculatedHeight = baseHeight + CGFloat(keyboardAdjustment)
        
        // 최소 높이와 최대 높이 제한 (모드와 확장 상태에 따라 조정)
        let minHeight: CGFloat = mode == .add ? 200 : (isExpanded ? 400 : 250)
        let maxHeight = UIScreen.main.bounds.height * 0.9
        
        return max(minHeight, min(calculatedHeight, maxHeight))
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            // 상단 바
            HStack {
                Button(action: {
                    if mode == .edit {
                        isPresented = false
                    } else {
                        mode = .edit
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text(mode == .edit ? "태그 수정" : "태그 추가")
                    .CFont(.headline03Bold)
                    .foregroundStyle(.text01)
                Spacer()
            }
            .padding(.top, 28)
            .padding(.horizontal, 16)
            
            switch mode {
            case .add:
                inputTextField
                selectedTagListViewAddMode
            case .edit:
                VStack(alignment: .leading, spacing: 12) {
                    Text("등록된 태그 \(selectedTags.count)/4")
                        .CFont(.subhead01Bold)
                        .foregroundStyle(.text02)
                    selectedTagListViewEditMode
                        .padding(.bottom, 32)
                    tagListTitle
                    allTagListViewEditMode
                }
                .padding(.horizontal, 16)
            }
            
            if keyboardHeight != 0 {
                Button("저장하기") {
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
                .padding(.bottom, 4)
            } else {
                Spacer()
            }
        }
        .readSize { size in
            contentSize = size
            let newHeight = dynamicHeight
            
            // 부드러운 애니메이션과 함께 높이 업데이트
            withAnimation(.easeInOut(duration: 0.3)) {
                sheetHeight = newHeight
            }
        }
        .onChange(of: mode) { _ in
            // mode 변경 시 높이 재계산
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                sheetHeight = dynamicHeight
            }
        }
        .onChange(of: isExpanded) { _ in
            // isExpanded 변경 시 높이 재계산
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                sheetHeight = dynamicHeight
            }
        }
        .onChange(of: selectedTags) { _ in
            // selectedTags 변경 시 높이 재계산 (태그 추가/삭제)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                sheetHeight = dynamicHeight
            }
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
    
    private var selectedTagListViewEditMode: some View {
        FlowLayout(spacing: 8, rowSpacing: 12) {
            ForEach(Array(selectedTags), id: \.self) { tag in
                Button {
                    onDeleteTag?(tag)
                } label: {
                    Text(tag)
                }
                .chipStyle(isSelected: true, selectedBackground: .text01, icon: Image(.xmark))
            }
            Button {
                withAnimation { mode = .add }
            } label: {
                Text("추가하기")
            }
            .chipStyle(
                isSelected: false,
                unselectedBackground: .clear,
                unselectedForeground: .text01,
                unselectedBorderColor: .divider,
                icon: Image(systemName: "plus")
            )
        }
    }
    
    private var tagListTitle: some View {
        HStack {
            Text("기존태그 보기")
                .CFont(.subhead01Bold)
                .foregroundStyle(.text02)
            Spacer()
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text(isExpanded ? "접기" : "더보기")
                        .CFont(.body02Regular)
                        .foregroundStyle(.text03)
                        .underline(color: .text03)
                    Image(.arrowDown)
                }
            }
        }
    }
    
    private var allTagListViewEditMode: some View {
        FlowLayout(spacing: 6, rowSpacing: 6) {
            ForEach(tags, id: \.self) { tag in
                Button {
                    onSaveTag?(tag)
                } label: {
                    Text(tag)
                }
                .chipStyle(
                    isSelected: selectedTags.contains(tag),
                    selectedBackground: .clear,
                    selectedForeground: .gray04,
                    unselectedBackground: .clear,
                    unselectedForeground: .text01,
                    selectedBorderColor: .divider,
                    unselectedBorderColor: .divider,
                    icon: selectedTags.contains(tag) ? Image(.check) : nil
                )
            }
        }
        .frame(maxHeight: isExpanded ? nil : 62)
        .clipped()
    }
    
    private var inputTextField: some View {
        VStack(alignment: .leading, spacing: 4) {
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
    }
    
    private var selectedTagListViewAddMode: some View {
        FlowLayout(spacing: 8, rowSpacing: 12) {
            ForEach(Array(selectedTags), id: \.self) { tag in
                Button {
                    onDeleteTag?(tag)
                } label: {
                    Text(tag)
                }
                .chipStyle(
                    isSelected: true,
                    selectedBackground: .text01,
                    icon: Image(.xmark)
                )
            }
        }
        .padding(.horizontal, 16)
    }
}
