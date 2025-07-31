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
    
    // 무한 스크롤을 위한 페이지네이션 상태
    @Published var isLoadingMore: Bool = false
    @Published var hasMoreData: Bool = true
    private var currentPage: Int = 0
    private let pageSize: Int = 20
    
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
        
        // 태그 변경 알림 구독
        NotificationCenter.default.publisher(for: NSNotification.Name("TagChanged"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshData()
                }
            }
            .store(in: &cancellables)
        
        // 즐겨찾기 변경 알림 구독
        NotificationCenter.default.publisher(for: .favoriteStatusChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshData()
                }
            }
            .store(in: &cancellables)
        
        // 스크린샷 삭제 알림 구독
        NotificationCenter.default.publisher(for: NSNotification.Name("ScreenshotDeleted"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.refreshData()
                }
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
        resetPagination()
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
            resetPagination()
            loadScreenshotsByTags()
            Task {
                await loadRelatedTags()
            }
        }
    }
    
    // 페이지네이션 상태 초기화
    private func resetPagination() {
        currentPage = 0
        hasMoreData = true
        filteredScreenshots = []
    }
    
    private func loadScreenshotsByTags() {
        isLoadingScreenshots = true
        Task {
            await loadScreenshotsForCurrentPage()
        }
    }
    
    // 현재 페이지의 스크린샷 로드
    private func loadScreenshotsForCurrentPage() async {
        do {
            print("selectedTags: \(selectedTags), page: \(currentPage)")
            
            let newScreenshots: [ScreenshotItemViewModel]
            
            if AccountStorage.shared.isGuest ?? true {
                // 게스트 모드에서는 로컬에서 전체 로드 (페이지네이션 미지원)
                newScreenshots = try await repository.loadByTags(selectedTags)
                hasMoreData = false // 로컬에서는 모든 데이터를 한 번에 로드
            } else {
                // 로그인 모드에서는 서버에서 페이지네이션으로 로드
                let loadedScreenshots = try await repository.loadByTags(selectedTags)
                // 실제로는 repository의 loadByTagsFromServer 메서드를 직접 호출해야 함
                newScreenshots = try await loadByTagsFromServerWithPagination(selectedTags, page: currentPage, size: pageSize)
            }
            
            if currentPage == 0 {
                // 첫 페이지인 경우 전체 교체
                filteredScreenshots = newScreenshots
            } else {
                // 추가 페이지인 경우 기존 데이터에 추가
                filteredScreenshots.append(contentsOf: newScreenshots)
            }
            
            // 로드된 데이터가 pageSize보다 적으면 더 이상 데이터가 없음
            if newScreenshots.count < pageSize {
                hasMoreData = false
            }
            
            await loadThumbnailsForNewScreenshots(newScreenshots)
            
        } catch {
            print("태그별 스크린샷 로딩 실패: \(error)")
            if currentPage == 0 {
                filteredScreenshots = []
            }
            hasMoreData = false
        }
        
        isLoadingScreenshots = false
        isLoadingMore = false
    }
    
    // 서버에서 페이지네이션으로 태그별 스크린샷 로드
    private func loadByTagsFromServerWithPagination(_ tags: [String], page: Int, size: Int) async throws -> [ScreenshotItemViewModel] {
        let result = await ImageService.shared.checkImageList(by: tags, page: page, size: size)
        
        switch result {
        case .success(let response):
            let serverItems = response.data.items.compactMap { serverItem -> ScreenshotItem? in
                let mappedTags = serverItem.tags
                
                let screenshotItem = ScreenshotItem(
                    id: String(serverItem.id),
                    imageData: Data(),
                    imageURL: serverItem.url,
                    fileName: serverItem.name,
                    createDate: serverItem.captureDate,
                    tags: mappedTags,
                    isFavorite: serverItem.isBookmarked
                )
                
                return screenshotItem
            }
            
            let viewModels = serverItems.map { item in
                repository.viewModel(for: item)
            }
            
            return viewModels
            
        case .failure(let error):
            throw error
        }
    }
    
    // 다음 페이지 로드 (무한 스크롤)
    func loadMoreScreenshots() {
        guard !isLoadingMore && hasMoreData && !selectedTags.isEmpty else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        Task {
            await loadScreenshotsForCurrentPage()
        }
    }
    
    // 스크롤 끝 감지를 위한 메서드
    func shouldLoadMore(currentItem: ScreenshotItemViewModel) -> Bool {
        guard let lastItem = filteredScreenshots.last else { return false }
        return currentItem.id == lastItem.id
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
    
    private func loadThumbnailsForNewScreenshots(_ screenshots: [ScreenshotItemViewModel]) async {
        // ✅ 병렬 로딩으로 여러 이미지를 동시에 다운로드
        await withTaskGroup(of: Void.self) { group in
            for itemVM in screenshots {
                group.addTask {
                    // 썸네일로 로드하여 더 빠르게 처리
                    await itemVM.loadFullImage()
                }
            }
        }
    }
    
    // 기존의 loadThumbnailsForFilteredScreenshots 메서드는 loadThumbnailsForNewScreenshots로 대체
    private func loadThumbnailsForFilteredScreenshots() async {
        await loadThumbnailsForNewScreenshots(filteredScreenshots)
    }
    
    func refreshData() async {
        // 1. 태그 목록 다시 로드
        await loadTags()
        
        // 2. 선택된 태그가 있다면 해당 데이터들도 다시 로드
        if !selectedTags.isEmpty {
            resetPagination()
            loadScreenshotsByTags()
            await loadRelatedTags()
        }
    }
    
    func clearAllSelections() {
        selectedTags = []
        relatedTags = []
        filteredScreenshots = []
        filteredTags = allTags
        resetPagination()
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
} 
