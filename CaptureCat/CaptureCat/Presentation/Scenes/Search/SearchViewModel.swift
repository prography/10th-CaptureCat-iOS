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
    @Published var selectedTags: [String] = []  // 다중 태그 선택
    @Published var relatedTags: [String] = []   // 연관 태그들
    @Published var filteredScreenshots: [ScreenshotItemViewModel] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingScreenshots: Bool = false
    
    private let repository = ScreenshotRepository.shared
    private var cancellables = Set<AnyCancellable>()
    private var networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
        // 검색어 변경 시 필터링 (태그가 선택되지 않은 경우에만)
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText in
                guard let self = self, self.selectedTags.isEmpty else { return }
                self.filterTags(with: searchText)
            }
            .store(in: &cancellables)
    }
    
    func loadTags() async {
        isLoading = true
        do {
            allTags = try await repository.fetchAllTags()
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
        // 이미 선택된 태그가 아닌 경우에만 추가
        guard !selectedTags.contains(tag) else { return }
        
        selectedTags.append(tag)
        searchText = ""
        loadScreenshotsByTags()
        Task {
            await loadRelatedTags()
        }
    }
    
    func removeTag(_ tag: String) {
        selectedTags.removeAll { $0 == tag }
        
        if selectedTags.isEmpty {
            clearAllSelections()
        } else {
            loadScreenshotsByTags()
            Task {
                await loadRelatedTags()
            }
        }
    }
    
    private func loadScreenshotsByTags() {
        isLoadingScreenshots = true
        do {
            filteredScreenshots = try repository.loadByTags(selectedTags)
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
    
    private func loadRelatedTags() async {
        guard !selectedTags.isEmpty else {
            relatedTags = []
            return
        }
        
        do {
            let otherTags = try await repository.fetchOtherTagsFromScreenshotsContaining(selectedTags)
            relatedTags = otherTags
        } catch {
            print("연관 태그 로딩 실패: \(error)")
            relatedTags = []
        }
    }
    
    private func loadThumbnailsForFilteredScreenshots() async {
        for itemVM in filteredScreenshots {
            await itemVM.loadThumbnail(size: CGSize(width: 150, height: 150))
        }
    }
    
    func clearAllSelections() {
        selectedTags = []
        relatedTags = []
        filteredScreenshots = []
        filteredTags = allTags
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
} 
