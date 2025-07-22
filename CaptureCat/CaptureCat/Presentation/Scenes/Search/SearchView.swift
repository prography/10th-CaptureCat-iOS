//
//  SearchView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI

struct SearchView: View {
    @StateObject private var viewModel = SearchViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 검색바
            searchBar
                .padding(.horizontal, 16)
                .padding(.top, 16)
            
            // 태그 바로가기 섹션
            tagShortcutSection
                .padding(.top, 32)
            
            Spacer()
        }
        .background(Color(.systemBackground))
        .task {
            viewModel.loadTags()
        }
    }
    
    // MARK: - 검색바
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray06)
            
            if let selectedTag = viewModel.selectedTag {
                // 선택된 태그 칩 표시
                HStack(spacing: 8) {
                    Button {
                        viewModel.clearSelectedTag()
                    } label: {
                        Text(selectedTag)
                    }
                    .chipStyle(
                        isSelected: true,
                        selectedBackground: .white,
                        selectedForeground: .primary01,
                        selectedBorderColor: .primary01,
                        icon: Image(.xmark)
                    )
                    
                    Spacer()
                }
            } else {
                // 기본 검색 TextField
                TextField("태그 이름으로 검색해 보세요", text: $viewModel.searchText)
                    .CFont(.body02Regular)
                    .foregroundColor(.gray06)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.gray03)
        .cornerRadius(8)
    }
    
    // MARK: - 태그 바로가기 섹션
    private var tagShortcutSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 섹션 제목
            HStack {
                Text("태그 바로가기")
                    .CFont(.subhead01Bold)
                    .foregroundColor(.text01)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // 태그 목록 (선택된 태그가 있으면 숨김)
            if viewModel.selectedTag == nil {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else if viewModel.filteredTags.isEmpty {
                    HStack {
                        Spacer()
                        Text(viewModel.searchText.isEmpty ? "저장된 태그가 없습니다" : "검색 결과가 없습니다")
                            .CFont(.body02Regular)
                            .foregroundColor(.text03)
                        Spacer()
                    }
                    .padding(.vertical, 20)
                } else {
                    tagGrid
                }
            } else {
                // 선택된 태그가 있을 때 결과 표시 영역
                selectedTagResults
            }
        }
    }
    
    // MARK: - 태그 그리드
    private var tagGrid: some View {
        let columns = [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ]
        
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(viewModel.filteredTags, id: \.self) { tag in
                Button {
                    viewModel.selectTag(tag)
                } label: {
                    Text(tag)
                        .CFont(.body02Regular)
                }
                .chipStyle(isSelected: false)
            }
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - 선택된 태그 결과
    private var selectedTagResults: some View {
        VStack(spacing: 16) {
            HStack {
                Text("'\(viewModel.selectedTag ?? "")'로 태그된 스크린샷")
                    .CFont(.body01Regular)
                    .foregroundColor(.text01)
                Spacer()
            }
            .padding(.horizontal, 16)
            
            if viewModel.isLoadingScreenshots {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if viewModel.filteredScreenshots.isEmpty {
                VStack(spacing: 8) {
                    Text("해당 태그가 포함된 스크린샷이 없습니다")
                        .CFont(.body02Regular)
                        .foregroundColor(.text03)
                    Text("다른 태그를 선택해보세요")
                        .CFont(.caption02Regular)
                        .foregroundColor(.text03)
                }
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 12) {
                        ForEach(viewModel.filteredScreenshots) { item in
                            NavigationLink {
                                DetailView(item: item)
                                    .navigationBarBackButtonHidden()
                                    .toolbar(.hidden, for: .navigationBar)
                            } label: {
                                ScreenshotItemView(viewModel: item, cornerRadius: 4) {
                                    HStack(spacing: 4) {
                                        ForEach(item.tags, id: \.self) { tag in
                                            Text(tag)
                                                .CFont(.caption01Semibold)
                                                .padding(.horizontal, 7.5)
                                                .padding(.vertical, 4.5)
                                                .background(Color.overlayDim)
                                                .foregroundColor(.white)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .padding(6)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
    }
    
    // MARK: - Grid Layout
    private let gridColumns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]
}

#Preview {
    SearchView()
}
