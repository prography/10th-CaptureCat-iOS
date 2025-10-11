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
    var onAddNewTag: ((String) -> Void)?
    var onDeleteTag: ((String) -> Void)?
    
    @State private var newTag: String = ""
    @State private var keyboardHeight: CGFloat = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 28) {
            // 상단 바
            HStack {
                Button(action: {
                    mode = .edit
                    isPresented = false
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
                    Text("더보기")
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
                    onDeleteTag?(tag)
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
                    icon: Image(.check)
                )
            }
        }
        .frame(maxHeight: isExpanded ? nil : 50)
    }
    
    private var inputTextField: some View {
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
    }
    
    private var selectedTagListViewAddMode: some View {
        FlowLayout(spacing: 8, rowSpacing: 12) {
            ForEach(Array(selectedTags), id: \.self) { tag in
                Button {
                    onDeleteTag?(tag)
                } label: {
                    Text(tag)
                }
                .chipStyle(isSelected: true, selectedBackground: .text01, icon: Image(.xmark))
            }
        }
        .padding(.horizontal, 16)
    }
}
