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
    @StateObject private var viewModel: DetailViewModel
    
    private let imageId: String
    
    init(imageId: String) {
        self.imageId = imageId
        self._viewModel = StateObject(wrappedValue: DetailViewModel(imageId: imageId))
    }
    
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
        .popupBottomSheet(isPresented: $viewModel.isShowingAddTagSheet) {
            AddTagSheet(
                tags: $viewModel.tags,
                selectedTags: $viewModel.tempSelectedTags,
                isPresented: $viewModel.isShowingAddTagSheet,
                onAddNewTag: { newTag in
                    viewModel.addNewTag(newTag)
                },
                onDeleteTag: { tag in
                    viewModel.deleteTag(tag)
                }
            )
        }
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
        .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") {
                viewModel.clearError()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
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
            homeViewModel.removeItem(with: imageId)
            router.pop()
        }
    }
    
    private var contentView: some View {
        VStack {
            CustomNavigationBar(
                title: viewModel.formattedDate,
                onBack: {
                    router.pop()
                },
                color: .white
            )
            .padding(.top, 10)
            
            imageSection
            
            Spacer()
            
            bottomBar
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
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
                Image((viewModel.item?.isFavorite ?? false) ? .selectedFavorite : .unselectedFavorite)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .padding(3)
                    .background(.overlayDim)
                    .clipShape(Circle())
            }
                .padding(.trailing, 16)
                .padding(.bottom, 32),
            alignment: .bottomTrailing
        )
    }
    
    private var tagOverlay: some View {
        HStack(spacing: 4) {
            ForEach(viewModel.tags, id: \.self) { tag in
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
            CustomNavigationBar(
                title: viewModel.formattedDate,
                onBack: { router.pop() },
                color: .white
            )
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
