//
//  TagSettingView.swift
//  CaptureCat
//
//  Created by minsong kim on 8/21/25.
//

import SwiftUI

struct TagSettingView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject var viewModel: TagSettingViewModel
    @State private var editTagSheetHeight: CGFloat = 180
    
    var body: some View {
        ZStack {
            VStack(spacing: 16) {
                navigationBar
                Divider()
                    .foregroundStyle(.divider)
                searchBar
                
                // 로딩 에러 메시지 표시
                if viewModel.showLoadError, let loadErrorMessage = viewModel.loadErrorMessage {
                    errorMessageView(loadErrorMessage)
                }
                
                if viewModel.isLoading {
                    loadingView
                } else if viewModel.tags.isEmpty {
                    noTagListView
                } else {
                    tagListView
                }
            }
            
            if authViewModel.authenticationState == .guest {
                VStack {
                    navigationBar
                    Spacer()
                    
                    Button {
                        authViewModel.authenticationState = .initial
                        router.pop()
                    } label: {
                        Text("로그인 후 이용하기")
                    }
                    .primaryStyle(fillWidth: false)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 80)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.overlayDim.opacity(0.3))
            }
        }
        .onAppear {
            UITextField.appearance().clearButtonMode = .whileEditing
            Task {
                await viewModel.loadTags()
            }
        }
        .sheet(isPresented: $viewModel.isShowingEditSheet, content: {
            NavigationStack {
                EditTagSheet(
                    tag: Binding(
                        get: { viewModel.selectedTag ?? Tag(id: 0, name: "") },
                        set: { viewModel.selectedTag = $0 }
                    ),
                    isPresented: $viewModel.isShowingEditSheet,
                    sheetHeight: $editTagSheetHeight,
                    errorMessage: $viewModel.editErrorMessage,
                    showError: $viewModel.showEditError,
                    onAddNewTag: { newTag in 
                        viewModel.updateTag(Tag(id: viewModel.selectedTag?.id ?? 0, name: newTag))
                    }
                )
                .presentationDetents([.height(editTagSheetHeight)])
                .animation(.easeInOut(duration: 0.3), value: editTagSheetHeight)
            }
        })
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
            
            Text("태그 설정")
                .CFont(.headline02Bold)
                .foregroundStyle(.text02)
            Text(viewModel.tagCountText)
                .CFont(.headline02Regular)
                .foregroundStyle(.text03)
            Spacer()
            
            Button{
                router.push(.tagEdit)
            } label: {
                Text("편집")
                    .CFont(.body01Regular)
                    .foregroundStyle(viewModel.isEditButtonEnabled ? .text03 : .gray03)
            }
            .disabled(!viewModel.isEditButtonEnabled)
        }
        .padding(.horizontal, 16)
        .padding(.top)
    }
    
    private var searchBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 기본 검색 TextField
            HStack {
                TextField("추가할 태그를 입력해주세요", text: $viewModel.addTag,
                          prompt: Text("추가할 태그를 입력해주세요")
                    .foregroundStyle(.text03)
                )
                .CFont(.body02Regular)
                .foregroundColor(.text02)
                .padding(.leading, 12)
                .padding(.trailing, 6)
                .padding(.vertical, 8)
                .cornerRadius(8)
                
                Button {
                    viewModel.registerTag()
                } label: {
                    Text("등록")
                        .CFont(.body02Regular)
                        .foregroundStyle(.text03)
                }
                .padding(.trailing, 12)
            }
            .cornerRadius(8)
            .background(Color.gray01)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(viewModel.showError ? Color.red : Color.clear, lineWidth: 1)
            )
            
            // 에러 메시지 표시
            if viewModel.showError, let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .CFont(.caption02Regular)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .animation(.easeInOut(duration: 0.2), value: viewModel.showError)
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("태그를 불러오는 중...")
                .CFont(.body01Regular)
                .foregroundStyle(.text03)
                .padding(.top, 8)
            Spacer()
        }
    }
    
    private var noTagListView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("등록된 태그가 없어요.")
                .CFont(.headline02Bold)
                .foregroundStyle(.text01)
            Text("태그로 분류하면 원하는 이미지를\n쉽게 찾을 수 있어요!")
                .CFont(.body01Regular)
                .multilineTextAlignment(.center)
                .foregroundStyle(.text03)
            Spacer()
        }
    }
    
    private var tagListView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(viewModel.tags, id: \.id) { tag in
                    TagRow(
                        tag: tag,
                        onEdit: { viewModel.edit(tag) }
                    )
                    
                    // 인셋된 구분선 느낌 (왼쪽 여백 맞추기)
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 0)
        }
    }
    
    private func errorMessageView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
                .font(.caption)
            
            Text(message)
                .CFont(.caption02Regular)
                .foregroundColor(.red)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 16)
    }
}
