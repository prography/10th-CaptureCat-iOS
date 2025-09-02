//
//  SearchResultView.swift
//  CaptureCat
//
//  Created by minsong kim on 8/31/25.
//

import SwiftUI

struct SearchResultView: View {
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: SearchViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            // 태그 바로가기 섹션
            selectedTagsSection
                .padding(.top, 32)
            
            Spacer()
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
    
    // MARK: - 검색바
    private var searchBar: some View {
        HStack {
            Button {
                router.pop()
            } label: {
                Image(.arrowBack)
                    .foregroundStyle(.text02)
            }
            .padding(.trailing, 12)
            // 선택된 태그들을 칩 형태로 표시
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.selectedTags, id: \.self) { tag in
                        Button {
                            viewModel.removeTag(tag)
                            
                            if viewModel.selectedTags.isEmpty {
                                router.pop()
                            }
                        } label: {
                            Text(tag)
                        }
                        .chipStyle(
                            isSelected: true,
                            selectedBackground: .clear,
                            selectedForeground: .primary01,
                            selectedBorderColor: .primary01,
                            icon: Image(.xmark),
                            horizontalPadding: 10,
                            verticalPadding: 5.5
                        )
                    }
                    Spacer()
                }
            }
            .padding(.leading, 12)
            .padding(.vertical, 4)
            .background(.clear)
            .border(.divider)
            .cornerRadius(8)
            Button {
                viewModel.selectedTags.removeAll()
                router.pop()
            } label: {
                Text("취소")
                    .CFont(.body02Regular)
                    .foregroundStyle(.text02)
            }
        }
    }
    
    // MARK: - 기본 태그 목록
    private var defaultTagsSection: some View {
        Group {
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                tagGrid(tags: viewModel.filteredTags)
            }
        }
    }
    
    // MARK: - 선택된 태그 상태 섹션
    private var selectedTagsSection: some View {
        VStack(spacing: 20) {
            // 연관 태그들 표시
            if !viewModel.relatedTags.isEmpty {
                tagGrid(tags: viewModel.relatedTags)
            }
            
            // 선택된 태그들의 검색 결과
            selectedTagResults
        }
    }
    
    // MARK: - 태그 그리드
    private func tagGrid(tags: [String]) -> some View {
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { tag in
                    Button {
                        viewModel.selectTag(tag)
                    } label: {
                        Text(tag)
                            .CFont(.body02Regular)
                    }
                    .chipStyle(isSelected: false)
                }
            }
        }
        .padding(.horizontal, 16)
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
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(viewModel.filteredScreenshots) { item in
                            Button {
                                router.push(.detail(id: item.id))
                            } label: {
                                ScreenshotItemView(viewModel: item, cornerRadius: 4) {
                                    TagFlowLayout(tags: item.tags.map { $0.name }, maxLines: 2)
                                        .padding(6)
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
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]
}
