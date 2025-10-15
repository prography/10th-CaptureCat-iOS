//
//  HomeViewModel2.swift
//  CaptureCat
//
//  Created by minsong kim on 9/11/25.
//

import Combine
import SwiftUI

@MainActor
class HomeViewModel: ObservableObject {
    @Published var selectedTag: Tag?
    @Published var allTags: [Tag] = []
    @Published var filteredScreenshots: [ScreenshotItemViewModel] = []
    @Published var isLoading: Bool = false
    @Published var isLoadingScreenshots: Bool = false
    
    // 무한 스크롤을 위한 페이지네이션 상태
    @Published var isLoadingMore: Bool = false
    @Published var hasMoreData: Bool = true
    private var currentPage: Int = 0
    private let pageSize: Int = 20
    
    private let repository: ScreenshotRepository
    private let service: SearchService
    
    private var searchTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init(repository: ScreenshotRepository, networkManager: NetworkManager) {
        self.repository = repository
        self.service = SearchService(networkManager: networkManager)
        
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
        } catch {
            print("태그 로딩 실패: \(error)")
            allTags = []
        }
        isLoading = false
    }
    
    func selectTag(_ tag: Tag) {
        // 이미 선택된 태그가 아닌 경우에만 추가
        guard selectedTag != tag else { return }
        
        selectedTag = tag
        resetPagination()
        loadScreenshotsByTags()
    }
    
    // 페이지네이션 상태 초기화
    private func resetPagination() {
        currentPage = 0
        hasMoreData = true
        filteredScreenshots = []
    }
    
    private func loadScreenshotFromLocal() {
        do {
            let localItems = try repository.loadAll()
            self.filteredScreenshots = localItems
        } catch {
            debugPrint("❌ loadScreenshotFromLocal Error: \(error.localizedDescription)")
            self.filteredScreenshots = []
        }
    }
    
    private func loadScreenshotFromServer() async {
        do {
            let serverItems = try await repository.loadFromServerOnly()
            
            // 중복 제거: 고유한 ID만 유지
            var uniqueItems: [ScreenshotItemViewModel] = []
            var seenIDs: Set<String> = []
            
            for item in serverItems {
                if !seenIDs.contains(item.id) {
                    seenIDs.insert(item.id)
                    uniqueItems.append(item)
                }
            }
            
            // ✅ @MainActor에서 직접 동기적 업데이트
            self.filteredScreenshots = uniqueItems
            debugPrint("✅ 서버 초기 로드 완료: \(uniqueItems.count)개 (중복 \(serverItems.count - uniqueItems.count)개 제거)")
        } catch {
            debugPrint("❌ 서버 로드 실패: \(error.localizedDescription)")
            // 서버 실패 시 빈 배열 (로컬 데이터 사용 X)
            self.filteredScreenshots = []
        }
        currentPage += 1
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
            let newScreenshots: [ScreenshotItemViewModel]
            
            if AccountStorage.shared.isGuest ?? true {
                // 게스트 모드에서는 로컬에서 로드
                if let selectedTag {
                    newScreenshots = try await repository.loadByTags([selectedTag.name])
                } else {
                    // 전체 탭일 때는 모든 로컬 데이터 로드
                    newScreenshots = try repository.loadAll()
                }
                hasMoreData = false // 로컬에서는 모든 데이터를 한 번에 로드
            } else if let selectedTag {
                // 로그인 모드에서는 서버에서 페이지네이션으로 로드
                _ = try await repository.loadByTags([selectedTag.name])
                // 실제로는 repository의 loadByTagsFromServer 메서드를 직접 호출해야 함
                newScreenshots = try await loadByTagsFromServerWithPagination([selectedTag.name], page: currentPage, size: pageSize)
            } else {
                // 전체 탭일 때 서버에서 페이지네이션으로 로드
                newScreenshots = try await repository.loadFromServerOnly(page: currentPage)
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
    private func loadByTagsFromServerWithPagination(_ tags: [String?], page: Int, size: Int) async throws -> [ScreenshotItemViewModel] {
        let result = await ImageService.shared.checkImageList(by: tags.compactMap { $0 ?? "" }, page: page, size: size)
        
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
//        guard !isLoadingMore && hasMoreData else {
//            return
//        }
        
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
        
        // 2. 페이지네이션 초기화 후 데이터 로드 (전체 탭 포함)
        resetPagination()
        loadScreenshotsByTags()
    }
    
    func clearAllSelections() {
        selectedTag = nil
        resetPagination()
        loadScreenshotsByTags()
    }
    
    private func mapTags(from dto: SearchDTO) -> [Tag] {
        // 예: dto.tags, dto.data.tags, dto.items.map(\.name) 등
        return dto.data
    }
    
    deinit {
        searchTask?.cancel()
        cancellables.forEach { $0.cancel() }
    }
}
