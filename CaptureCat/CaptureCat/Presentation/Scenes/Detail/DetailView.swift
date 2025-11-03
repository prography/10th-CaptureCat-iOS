//
//  DetailView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI

struct DetailView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var homeViewModel: HomeViewModel
    @StateObject var viewModel: DetailViewModel
    @State private var mode: TagSheetMode = .edit
    @State var isExpanded = false
    @State private var tagSheetHeight: CGFloat = 300 // edit 모드를 고려한 더 큰 기본값
    
    let imageId: String
    
    var body: some View {
        ZStack {
            Color.secondary01
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.item != nil {
                contentView
            } else {
                errorView
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddTagSheet, content: {
                TagSheet(
                    mode: $mode,
                    isExpanded: $isExpanded,
                    tags: $viewModel.tags,
                    selectedTags: $viewModel.tempSelectedTags,
                    isPresented: $viewModel.isShowingAddTagSheet,
                    sheetHeight: $tagSheetHeight,
                    errorMessage: $viewModel.errorMessage,
                    showError: $viewModel.showError,
                    onAddNewTag: { newTag in viewModel.addNewTag(newTag) },
                    onDeleteTag: { tag in viewModel.deleteTag(tag) },
                    onSaveTag: { tag in viewModel.addTagByChip(tag) }
                )
                .presentationDetents([.height(tagSheetHeight)])
                .animation(.easeInOut(duration: 0.3), value: tagSheetHeight)
                .ignoresSafeArea(.keyboard, edges: .bottom)
        })
        .popUp(
            isPresented: $viewModel.isDeleted,
            title: "삭제할까요?",
            message: "1개의 항목을 삭제하시겠습니까?\n삭제시 복구할 수 없습니다.",
            cancelTitle: "취소",
            confirmTitle: "삭제"
        ) {
            Task {
                await handleDelete()
            }
        }
        .task {
            MixpanelManager.shared.trackDetailView(id: imageId)
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
    
    @MainActor
    private func handleDelete() async {
        await viewModel.deleteScreenshot()
        
        // 삭제 성공 시 HomeView에서 아이템 제거하고 dismiss
        if viewModel.errorMessage == nil {
//            homeViewModel.removeItem(with: imageId)
            router.pop()
        }
    }
    
    private var contentView: some View {
        VStack {
            HStack {
                Button { router.pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
                
                Text(viewModel.item?.createDate ?? "")
                    .CFont(.headline03Bold)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            imageSection
            
            Spacer()
            
            bottomBar
                .padding(.horizontal, 16)
        }
    }
    
    private var imageSection: some View {
        ZStack(alignment: .bottomLeading) {
            Image(uiImage: viewModel.displayImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .padding()
            
            tagOverlay
        }
        .overlay(
            Button {
                viewModel.toggleFavorite()
            } label: {
                Image(viewModel.isFavorite ? .favoriteSelected : .favoriteUnselected)
                    .renderingMode(.template)
                    .resizable()
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
                    .padding(3)
                    .shadow(radius: 8, y: 4)
            }
                .padding(.trailing, 16)
                .padding(.bottom, 32),
            alignment: .bottomTrailing
        )
    }
    
    private var tagOverlay: some View {
        HStack(spacing: 4) {
            ForEach(Array(viewModel.tempSelectedTags), id: \.self) { tag in
                Text(tag)
                    .CFont(.caption01Semibold)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.overlayDim)
                    .foregroundColor(.white)
                    .cornerRadius(4)
            }
        }
        .padding(.bottom, 32)
        .padding(.horizontal, 16)
    }
    
    private var bottomBar: some View {
        HStack {
            Spacer()
            
            Button {
                viewModel.showAddTagSheet()
            } label: {
                VStack {
                    Image(.editSquare)
                    Text("태그 편집")
                        .CFont(.body02Regular)
                }
            }
            .foregroundStyle(.white)
            .disabled(viewModel.isLoading)
            
            Spacer()
            
            Button {
                viewModel.showDeleteConfirmation()
            } label: {
                VStack {
                    Image(.delete2)
                    Text("삭제")
                        .CFont(.body02Regular)
                }
            }
            .foregroundStyle(.white)
            .disabled(viewModel.isLoading)
            
            Spacer()
        }
    }
    
    private var loadingView: some View {
        VStack {
            HStack {
                Button { router.pop() } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.white)
                }
                
                Text(viewModel.item?.createDate ?? "")
                    .CFont(.headline03Bold)
                    .foregroundColor(.white)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            
            Spacer()
            
            ProgressView("로딩 중...")
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    private var errorView: some View {
        VStack {
            CustomNavigationBar(
                title: "오류",
                onBack: { router.pop() },
                color: .white
            )
            .padding(.top, 10)
            
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                
                Text("이미지를 불러올 수 없습니다")
                    .CFont(.headline01Bold)
                    .foregroundColor(.white)
                
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .CFont(.body02Regular)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                Button {
                    router.pop()
                } label: {
                    Text("돌아가기")
                        .CFont(.body01Regular)
                        .foregroundColor(.secondary01)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.white)
                        .cornerRadius(8)
                }
                .padding(.top, 16)
            }
            
            Spacer()
        }
    }
}
