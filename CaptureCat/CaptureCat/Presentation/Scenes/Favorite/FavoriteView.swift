//
//  FavoriteView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import SwiftUI

struct FavoriteView: View {
    @EnvironmentObject var router: Router
    @StateObject var viewModel: FavoriteViewModel
    
    var body: some View {
        VStack(spacing: 12) {
            navigationBar
            favoriteTabSelection
            
            if viewModel.isLoading {
                ProgressView("로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.favoriteItems.isEmpty {
                noFavoriteItems
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(Array(viewModel.favoriteItems.enumerated()), id: \.offset) { index, item in
                            Button {
                                router.push(.detail(id: item.id))
                            } label: {
                                ScreenshotItemView(viewModel: item, cornerRadius: 4) {
                                    EmptyView()
                                }
                                .overlay(
                                    Button {
                                        // 즐겨찾기 해제 (즉시 UI에서 제거)
                                        viewModel.toggleFavorite(item)
                                    } label: {
                                        Image(.favoriteSelected) // 즐겨찾기 페이지에서는 항상 선택된 상태
                                            .renderingMode(.template)
                                            .resizable()
                                            .foregroundStyle(.white)
                                            .frame(width: 24, height: 24)
                                            .padding(3)
                                    }
                                    .padding(8), alignment: .bottomLeading
                                )
                            }
                            .onAppear {
                                // 페이지네이션: 끝에서 3번째 아이템에 도달하면 다음 페이지 로드
                                if viewModel.shouldLoadNextPage(for: index) {
                                    Task {
                                        await viewModel.loadNextPage()
                                        
                                        // 새로 로드된 아이템들의 이미지 로드
                                        let currentItems = viewModel.favoriteItems
                                        let startIndex = max(0, index)
                                        let endIndex = min(currentItems.count, startIndex + 10)
                                        
                                        for i in startIndex..<endIndex {
                                            if i < viewModel.favoriteItems.count {
                                                await viewModel.favoriteItems[i].loadFullImage()
                                            }
                                        }
                                    }
                                }
                                
                                // 아이템이 나타날 때 이미지 로드
                                Task {
                                    await item.loadFullImage()
                                }
                            }
                        }
                        
                        // 페이지 로딩 인디케이터
                        if viewModel.isLoadingPage {
                            HStack {
                                Spacer()
                                ProgressView()
                                    .padding()
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .refreshable {
                    // Pull to refresh
                    await viewModel.refreshFavoriteItems(tag: viewModel.selectedTag)
                }
            }
        }
        .background(Color(.systemBackground))
        .task {
            await viewModel.loadTags()
            await viewModel.loadFavoriteItems(tag: nil)
            
            // 모든 아이템의 이미지 로드
            let currentItems = Array(viewModel.favoriteItems)
            for itemVM in currentItems {
                await itemVM.loadFullImage()
            }
        }
        .alert("오류", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("확인") {
                viewModel.clearErrorMessage()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private var navigationBar: some View {
        HStack {
            Text("좋아요")
                .CFont(.headline02Bold)
                .foregroundStyle(.text02)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top)
    }
    
    private var favoriteTabSelection: some View {
        HStack {
            TabSection(
                tags: viewModel.allTags,
                selectedTag: Binding(
                    get: { viewModel.selectedTag },
                    set: { viewModel.selectedTag = $0 }
                ),
                showAll: true
            ) { newTag in
                Task {
                    await viewModel.loadFavoriteItems(tag: newTag)
                }
            }
            
            Button {
                router.push(.tagSetting)
            } label: {
                Image(.toc)
                    .resizable()
                    .frame(width: 20, height: 20)
                    .opacity(0.9)
            }
            .background(.clear)
            .padding(.trailing, 4)
            .padding(.bottom, 2)
        }
        .padding(.horizontal, 8)
    }
    
    private var noFavoriteItems: some View {
        VStack(spacing: 8) {
            Text("아직 좋아요가 없어요.")
                .CFont(.headline02Bold)
                .foregroundStyle(.text03)
            Text("자주 보고 싶은 이미지에\n좋아요를 누르면 빠르게 찾아볼 수 있어요")
                .CFont(.body01Regular)
                .foregroundStyle(.text03)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Grid Layout
    private let gridColumns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]
}
