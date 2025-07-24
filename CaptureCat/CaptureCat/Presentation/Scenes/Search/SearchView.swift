//
//  SearchView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject var router: Router
    @StateObject var viewModel: SearchViewModel
    
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
            await viewModel.loadTags()
        }
    }
    
    // MARK: - 검색바
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray06)
            
            if !viewModel.selectedTags.isEmpty {
                // 선택된 태그들을 칩 형태로 표시
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.selectedTags, id: \.self) { tag in
                            Button {
                                viewModel.removeTag(tag)
                            } label: {
                                Text(tag)
                            }
                            .chipStyle(isSelected: true, selectedBackground: .white, selectedForeground: .primary01, selectedBorderColor: .primary01, icon: Image(.xmark))
                        }
                        Spacer()
                    }
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
            // 태그 목록
            if viewModel.selectedTags.isEmpty {
                HStack {
                    Text("태그 바로가기")
                        .CFont(.subhead01Bold)
                        .foregroundColor(.text01)
                    Spacer()
                }
                .padding(.horizontal, 16)
                // 기본 상태: 모든 태그 표시
                defaultTagsSection
            } else {
                // 선택된 태그가 있을 때: 연관 태그와 결과 표시
                selectedTagsSection
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
            } else if viewModel.filteredScreenshots.isEmpty {
                VStack(spacing: 8) {
                    Text("해당 태그들이 모두 포함된 스크린샷이 없습니다")
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
                            Button {
                                router.push(.detail(id: item.id))
                            } label: {
                                ScreenshotItemView(viewModel: item, cornerRadius: 4) {
                                    TagFlowLayout(tags: item.tags, maxLines: 2)
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

//#Preview {
//    SearchView()
//}
