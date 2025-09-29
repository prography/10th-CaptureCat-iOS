//
//  HomeView2.swift
//  CaptureCat
//
//  Created by minsong kim on 9/11/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var showChannel = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 12)
            
            TabSection(
                tags: viewModel.allTags,
                selectedTag: Binding(
                    get: { viewModel.selectedTag },
                    set: { viewModel.selectedTag = $0 }
                ),
                showAll: true
            ) { newTag in
                if let tag = newTag {
                    viewModel.selectTag(tag)
                } else {
                    viewModel.clearAllSelections()
                }
                
                Task {
                    await viewModel.refreshData()
                }
            }
            .padding(.horizontal, 8)
            
            csBanner
                .padding(.bottom, 8)
            
            ZStack {
                if viewModel.allTags.isEmpty {
                    VStack(spacing: 8) {
                        Text("아직 태그가 없어요")
                            .CFont(.headline02Bold)
                            .foregroundStyle(.text03)
                        Text("스크린샷을 태그해 정리해보세요!")
                            .CFont(.body01Regular)
                            .foregroundStyle(.text03)
                    }
                    .multilineTextAlignment(.center)
                    .padding(.top, 150)
                } else {
                    selectedTagResults
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground))
        .task {
            await viewModel.loadTags()
        }
        .onAppear {
            Task {
                await viewModel.refreshData()
            }
        }
    }
    
    private var header: some View {
        HStack {
            Image(.mainLogo)
            Spacer()
            Button { router.push(.setting) } label: {
                Image(.accountCircle)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var csBanner: some View {
        Button {
            showChannel = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("채팅으로 오류 제보하기")
                        .CFont(.subhead01Bold)
                        .foregroundStyle(.primary01)
                        .padding(.top, 8)
                    Text("보내주신 내용은 모두 확인하고 답변드려요")
                        .CFont(.caption02Regular)
                        .foregroundStyle(.text02)
                }
                Spacer()
                Image(.bannerCatch)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.primaryLow)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - 선택된 태그 결과
    private var selectedTagResults: some View {
        VStack(spacing: 16) {
            if viewModel.isLoadingScreenshots {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 4) {
                        ForEach(viewModel.filteredScreenshots) { item in
                            Button {
                                router.push(.detail(id: item.id))
                            } label: {
                                ScreenshotItemView(viewModel: item, cornerRadius: 4) {
                                    EmptyView()
                                }
                            }
                            .onAppear {
                                // 마지막 아이템에 도달했을 때 더 많은 데이터 로드
                                if viewModel.shouldLoadMore(currentItem: item) {
                                    viewModel.loadMoreScreenshots()
                                }
                            }
                        }
                        
                        // 추가 로딩 인디케이터
                        if viewModel.isLoadingMore {
                            VStack {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    // MARK: - Grid Layout
    private let gridColumns = [
        GridItem(.adaptive(minimum: 100), spacing: 4)
    ]
}
