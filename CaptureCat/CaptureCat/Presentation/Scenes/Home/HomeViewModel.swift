//
//  HomeViewModel2.swift
//  CaptureCat
//
//  Created by minsong kim on 9/11/25.
//

import Combine
import SwiftUI
import Photos

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
    
    // For toast
    let toastPublisher = PassthroughSubject<String, Never>()
    var isSavedImages = PassthroughSubject<Bool, Never>()
    
    private let repository: ScreenshotRepository
    private let service: SearchService
    
    @Published var savedImages: [ScreenshotItemViewModel] = []
    
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
        debugPrint("🏷️ loadTags 시작")
        isLoading = true
        do {
            allTags = try await repository.fetchAllTags()
            debugPrint("🏷️ 태그 로딩 성공: \(allTags.count)개")
        } catch {
            debugPrint("❌ 태그 로딩 실패: \(error)")
            // 실패 시 기존 태그 유지 (빈 배열로 초기화하지 않음)
            debugPrint("🔄 기존 태그 유지: \(allTags.count)개")
        }
        isLoading = false
        debugPrint("🏷️ loadTags 완료 - allTags.count: \(allTags.count)")
    }
    
    func selectTag(_ tag: Tag) async {
        // 이미 선택된 태그가 아닌 경우에만 추가
        guard selectedTag != tag else { return }
        
        selectedTag = tag
        resetPagination()
        filteredScreenshots = [] // 태그 선택 시에는 화면 비우기
        await loadScreenshotsByTags()
    }
    
    // 페이지네이션 상태 초기화
    private func resetPagination() {
        currentPage = 0
        hasMoreData = true
        // filteredScreenshots는 새 데이터가 로드될 때만 교체
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
    
    private func loadScreenshotsByTags() async {
        isLoadingScreenshots = true
        await loadScreenshotsForCurrentPage()
        isLoadingScreenshots = false
    }
    
    // 현재 페이지의 스크린샷 로드
    private func loadScreenshotsForCurrentPage() async {
        debugPrint("📱 loadScreenshotsForCurrentPage 시작 - currentPage: \(currentPage), selectedTag: \(selectedTag?.name ?? "nil")")
        
        // Task 취소 확인
        guard !Task.isCancelled else {
            debugPrint("📱 Task가 취소됨 - loadScreenshotsForCurrentPage 중단")
            return
        }
        
        do {
            let newScreenshots: [ScreenshotItemViewModel]
            
            if AccountStorage.shared.isGuest ?? true {
                debugPrint("📱 게스트 모드 - 로컬에서 로드")
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
            newScreenshots = try await loadByTagsFromServerWithPagination([selectedTag.name], page: currentPage, size: pageSize)
            } else {
                // 전체 탭일 때 서버에서 페이지네이션으로 로드
                newScreenshots = try await repository.loadFromServerOnly(page: currentPage)
            }
            
            // Task 취소 확인
            guard !Task.isCancelled else {
                debugPrint("📱 Task가 취소됨 - 데이터 로드 후 중단")
                return
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
            // Task 취소 에러는 무시
            if (error as NSError).code == NSURLErrorCancelled {
                debugPrint("📱 네트워크 요청이 취소됨 - 무시")
                return
            }
            debugPrint("❌ 태그별 스크린샷 로딩 실패: \(error)")
            // 첫 페이지가 아닌 경우에만 기존 데이터 유지
            if currentPage == 0 {
                // 첫 페이지에서 실패한 경우에만 빈 배열로 설정
                filteredScreenshots = []
                debugPrint("📱 첫 페이지 로딩 실패 - 빈 배열로 설정")
            } else {
                debugPrint("📱 추가 페이지 로딩 실패 - 기존 데이터 유지")
            }
            hasMoreData = false
        }
        isLoadingMore = false
    }
    
    // 서버에서 페이지네이션으로 태그별 스크린샷 로드
    private func loadByTagsFromServerWithPagination(_ tags: [String], page: Int, size: Int) async throws -> [ScreenshotItemViewModel] {
        // Task 취소 확인
        guard !Task.isCancelled else {
            debugPrint("📱 Task가 취소됨 - loadByTagsFromServerWithPagination 중단")
            throw URLError(.cancelled)
        }
        
        // repository의 loadByTags 메서드를 사용하되, 페이지네이션을 위해 직접 ImageService 호출
        let result = await ImageService.shared.checkImageList(by: tags, page: page, size: size)
        
        // Task 취소 확인
        guard !Task.isCancelled else {
            debugPrint("📱 Task가 취소됨 - 네트워크 응답 후 중단")
            throw URLError(.cancelled)
        }
        
        switch result {
        case .success(let response):
            let serverItems = response.data.items.map { serverItem in
                ScreenshotItem(serverItem: serverItem)
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
        // 이전 Task 취소 방지
        searchTask?.cancel()
        
        // 1. 태그 목록 다시 로드 (완료까지 대기)
        await loadTags()
        
        // 2. 페이지네이션 초기화 후 데이터 로드 (전체 탭 포함)
        resetPagination()
        
        // 3. 로딩 상태 설정 후 데이터 로드
        isLoadingScreenshots = true
        debugPrint("📢 refresh Data 시자")
        
        // Task 생성하여 취소 방지
        searchTask = Task {
            do {
                if selectedTag != nil {
                    await loadScreenshotsByTags()
                } else {
                    await loadScreenshotsForCurrentPage()
                }
            } catch {
                debugPrint("❌ refreshData 중 에러 발생: \(error)")
                // 에러가 발생해도 기존 데이터 유지
            }
        }
        
        await searchTask?.value
        isLoadingScreenshots = false
    }
    
    func clearAllSelections() async {
        selectedTag = nil
        resetPagination()
        filteredScreenshots = [] // 전체 탭 선택 시에는 화면 비우기
        
        isLoadingScreenshots = true
        await loadScreenshotsForCurrentPage()
        isLoadingScreenshots = false
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

extension HomeViewModel {
    /// UserDefaults 설정에 따라 원본 사진 삭제 여부 결정
    func deleteOriginalsIfEnabled(_ itemVMs: [ScreenshotItemViewModel]) async {
        let shouldDelete = UserDefaults.standard.deleteOriginalsAfterSave
        
        guard shouldDelete else {
            debugPrint("🔧 원본 사진 삭제 설정이 비활성화되어 있습니다")
            return
        }
        
        debugPrint("🗑️ 원본 사진 삭제 설정이 활성화되어 있어 삭제를 시작합니다")
        await deleteOriginalAssets(itemVMs)
    }
    
    /// 사진 라이브러리 쓰기 권한 확인
    private func checkPhotoLibraryWritePermission() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized:
            return true
        case .notDetermined:
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return newStatus == .authorized
        case .denied, .restricted:
            debugPrint("❌ 사진 라이브러리 쓰기 권한이 거부되었습니다")
            return false
        case .limited:
            // limited 권한에서도 삭제는 가능할 수 있음
            return true
        @unknown default:
            return false
        }
    }
    
    /// 원본 PHAsset들을 갤러리에서 삭제
    private func deleteOriginalAssets(_ itemVMs: [ScreenshotItemViewModel]) async {
        // 1. 권한 확인
        guard await checkPhotoLibraryWritePermission() else {
            debugPrint("❌ 사진 라이브러리 쓰기 권한이 없어 원본 사진을 삭제할 수 없습니다")
            return
        }
        
        // 2. PHAsset 가져오기
        let assetIds = itemVMs.map { $0.id }
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: assetIds, options: nil)
        
        var assetsToDelete: [PHAsset] = []
        fetchResult.enumerateObjects { asset, _, _ in
            assetsToDelete.append(asset)
        }
        
        guard !assetsToDelete.isEmpty else {
            debugPrint("⚠️ 삭제할 PHAsset이 없습니다")
            return
        }
        
        debugPrint("🗑️ 원본 사진 삭제 시작: \(assetsToDelete.count)개")
        
        // 3. 실제 삭제 수행
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
            }) { success, error in
                if success {
                    debugPrint("✅ 원본 사진 삭제 완료: \(assetsToDelete.count)개")
                    Task { @MainActor in
                        self.toastPublisher.send("\(assetsToDelete.count)장 삭제되었어요.")
                    }
                } else {
                    let errorMessage = error?.localizedDescription ?? "Unknown error"
                    debugPrint("❌ 원본 사진 삭제 실패: \(errorMessage)")
                }
                continuation.resume()
            }
        }
    }
    
    /// 태그된 이미지 ID들을 UserDefaults에 저장
    func saveTaggedImageIds(_ itemVMIDs: [String]) {
        let imageIds = Set(itemVMIDs)
        var existingIds = UserDefaults.standard.taggedImageIds
        existingIds.formUnion(imageIds)
        UserDefaults.standard.taggedImageIds = existingIds
        
        debugPrint("💾 태그된 이미지 ID 저장 완료: \(imageIds.count)개 추가, 총 \(existingIds.count)개")
    }
}
