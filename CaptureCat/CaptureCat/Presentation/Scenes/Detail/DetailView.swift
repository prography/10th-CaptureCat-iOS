//
//  DetailView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var homeViewModel: HomeViewModel
    let item: ScreenshotItemViewModel
    @StateObject private var viewModel: DetailViewModel
    
    init(item: ScreenshotItemViewModel) {
        self.item = item
        self._viewModel = StateObject(wrappedValue: DetailViewModel(item: item))
    }
    
    var body: some View {
        ZStack {
            Color.secondary01
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else {
                contentView
            }
        }
        .popupBottomSheet(isPresented: $viewModel.isShowingAddTagSheet) {
            AddTagSheet(
                tags: .constant(viewModel.tags),
                selectedTags: $viewModel.tempSelectedTags,
                isPresented: $viewModel.isShowingAddTagSheet
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
            homeViewModel.removeItem(with: item.id)
            dismiss()
        }
    }
    
    private var contentView: some View {
        VStack {
            CustomNavigationBar(
                title: viewModel.formattedDate,
                onBack: { dismiss() },
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
                onBack: { dismiss() },
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
}
