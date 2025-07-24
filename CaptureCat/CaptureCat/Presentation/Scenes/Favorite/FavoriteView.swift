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
        VStack(spacing: 0) {
            CustomNavigationBar(title: "즐겨찾기") {
                router.pop()
            }
            .padding(.top, 10)
            .padding(.bottom, 12)
            
            if viewModel.isLoading {
                ProgressView("로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.favoriteItems.isEmpty {
                Text("즐겨찾기한 스크린샷이 없습니다.")
                    .foregroundStyle(.secondary)
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
                                        Image(.selectedFavorite) // 즐겨찾기 페이지에서는 항상 선택된 상태
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                            .padding(3)
                                            .background(.overlayDim)
                                            .clipShape(Circle())
                                    }
                                        .padding(16),
                                    alignment: .bottomTrailing
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
                    await viewModel.refreshFavoriteItems()
                }
            }
        }
        .background(Color(.systemBackground))
        .task {
            await viewModel.loadFavoriteItems()
            
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
    
    // MARK: - Grid Layout
    private let gridColumns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]
}
