//
//  SearchViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/25/25.
//

import SwiftUI
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var allTags: [String] = []
    @Published var filteredTags: [String] = []
    @Published var selectedTag: String? = nil
    @Published var filteredScreenshots: [ScreenshotItemViewModel] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingScreenshots: Bool = false
    
    private let repository = ScreenshotRepository.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // 검색어 변경 시 필터링 (태그가 선택되지 않은 경우에만)
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                guard let self = self, self.selectedTag == nil else { return }
                self.filterTags(with: searchText)
            }
            .store(in: &cancellables)
    }
    
    func loadTags() {
        isLoading = true
        do {
            allTags = try repository.fetchAllTags()
            filteredTags = allTags
        } catch {
            print("태그 로딩 실패: \(error)")
            allTags = []
            filteredTags = []
        }
        isLoading = false
    }
    
    private func filterTags(with searchText: String) {
        if searchText.isEmpty {
            filteredTags = allTags
        } else {
            filteredTags = allTags.filter { tag in
                tag.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func selectTag(_ tag: String) {
        selectedTag = tag
        searchText = ""
        loadScreenshotsByTag(tag)
    }
    
    private func loadScreenshotsByTag(_ tag: String) {
        isLoadingScreenshots = true
        do {
            filteredScreenshots = try repository.loadByTag(tag)
            // 썸네일 로드
            Task {
                await loadThumbnailsForFilteredScreenshots()
            }
        } catch {
            print("태그별 스크린샷 로딩 실패: \(error)")
            filteredScreenshots = []
        }
        isLoadingScreenshots = false
    }
    
    private func loadThumbnailsForFilteredScreenshots() async {
        for itemVM in filteredScreenshots {
            await itemVM.loadThumbnail(size: CGSize(width: 150, height: 150))
        }
    }
    
    func clearSelectedTag() {
        selectedTag = nil
        filteredScreenshots = []
        filteredTags = allTags
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
} 
