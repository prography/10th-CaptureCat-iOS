//
//  HomeViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI
import Photos
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Dependencies
    private let repository = ScreenshotRepository.shared
    @Published var itemVMs: [ScreenshotItemViewModel] = []
    @Published var favoriteItemVMs: [ScreenshotItemViewModel] = []
    @Published var currentFavoriteIndex: Int = 0
    @Published var isLoadingPage = false
    @Published var isInitialLoading = false
    @Published var isLoadingFavoritePage = false
    private var canLoadMorePages = true
    private var canLoadMoreFavoritePages = true
    private var page: Int = 0
    private var favoritePage: Int = 0
    private var hasLoadedInitialData = false
    
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일"
        return formatter
    }()
    
    private var cancellables = Set<AnyCancellable>()
    private var netwworkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.netwworkManager = networkManager
        setupNotificationObservers()
    }
    
    /// 스마트 로딩 (로그인 상태에 따라 자동 분기) - 초기 로딩용
    func loadScreenshots() async {
        guard !hasLoadedInitialData else { return }
        
        isInitialLoading = true
        defer { isInitialLoading = false }
        
        let isGuest = AccountStorage.shared.isGuest ?? true
        debugPrint("🔍 - 최종 게스트 여부: \(isGuest)")
        
        if isGuest {
            // 게스트 모드: 로컬에서만 로드
            loadScreenshotFromLocal()
        } else {
            // 로그인 모드: 서버에서만 로드
            await loadFromServerOnly()
        }
        
        await loadFavorite()
        
        hasLoadedInitialData = true
    }
    
    /// 강제 새로고침 (삭제 후 등에 사용)
    func refreshScreenshots() async {
        hasLoadedInitialData = false
        page = 0
        canLoadMorePages = true
        itemVMs = []
        await loadScreenshots()
    }
    
    func loadNextPageServer() async {
        guard !isLoadingPage, canLoadMorePages else { return }
        isLoadingPage = true
        defer { isLoadingPage = false }
        
        do {
            let serverItems = try await repository.loadFromServerOnly(page: page)
            if serverItems.isEmpty {
                canLoadMorePages = false         // 더 이상 불러올 게 없으면 멈춤
            } else {
                // 중복 제거: 기존 ID와 겹치지 않는 아이템만 추가
                let existingIDs = Set(self.itemVMs.map { $0.id })
                let newItems = serverItems.filter { !existingIDs.contains($0.id) }
                
                if !newItems.isEmpty {
                    self.itemVMs += newItems
                    debugPrint("✅ 새로운 아이템 \(newItems.count)개 추가 (중복 \(serverItems.count - newItems.count)개 제외)")
                } else {
                    debugPrint("⚠️ 모든 아이템이 중복이므로 추가하지 않음")
                }
                
                page += 1
            }
        } catch {
            debugPrint("❌ 서버 로드 실패: \(error.localizedDescription)")
        }
    }
    
    func loadScreenshotFromLocal() {
        do {
            let localItems = try ScreenshotRepository.shared.loadAll()
            self.itemVMs = localItems
        } catch {
            debugPrint("❌ loadScreenshotFromLocal Error: \(error.localizedDescription)")
            self.itemVMs = []
        }
    }
    
    func loadFromServerOnly() async {
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
            self.itemVMs = uniqueItems
            debugPrint("✅ 서버 초기 로드 완료: \(uniqueItems.count)개 (중복 \(serverItems.count - uniqueItems.count)개 제거)")
        } catch {
            debugPrint("❌ 서버 로드 실패: \(error.localizedDescription)")
            // 서버 실패 시 빈 배열 (로컬 데이터 사용 X)
            self.itemVMs = []
        }
        page += 1
    }
    
    func loadFavorite() async {
        do {
            let serverItems = try await repository.loadFavoriteFromServerOnly(page: 0, size: 20)
            
            // 중복 제거: 고유한 ID만 유지
            var uniqueItems: [ScreenshotItemViewModel] = []
            var seenIDs: Set<String> = []
            
            for item in serverItems {
                if !seenIDs.contains(item.id) {
                    seenIDs.insert(item.id)
                    uniqueItems.append(item)
                }
            }
            
            self.favoriteItemVMs = uniqueItems
            self.favoritePage = 1 // 초기 로드 후 페이지 설정
            self.canLoadMoreFavoritePages = !serverItems.isEmpty
            debugPrint("✅ 즐겨찾기 로드 완료: \(uniqueItems.count)개 (중복 \(serverItems.count - uniqueItems.count)개 제거)")
        } catch {
            debugPrint("❌ 즐겨찾기 서버 로드 실패: \(error.localizedDescription)")
        }
    }
    
    /// 즐겨찾기 다음 페이지 로드
    func loadNextFavoritePage() async {
        guard !isLoadingFavoritePage, canLoadMoreFavoritePages else { return }
        isLoadingFavoritePage = true
        defer { isLoadingFavoritePage = false }
        
        do {
            let serverItems = try await repository.loadFavoriteFromServerOnly(page: favoritePage, size: 20)
            if serverItems.isEmpty {
                canLoadMoreFavoritePages = false
            } else {
                // 중복 제거: 기존 ID와 겹치지 않는 아이템만 추가
                let existingIDs = Set(self.favoriteItemVMs.map { $0.id })
                let newItems = serverItems.filter { !existingIDs.contains($0.id) }
                
                if !newItems.isEmpty {
                    self.favoriteItemVMs += newItems
                    debugPrint("✅ 새로운 즐겨찾기 아이템 \(newItems.count)개 추가 (중복 \(serverItems.count - newItems.count)개 제외)")
                } else {
                    debugPrint("⚠️ 모든 즐겨찾기 아이템이 중복이므로 추가하지 않음")
                }
                
                favoritePage += 1
            }
        } catch {
            debugPrint("❌ 즐겨찾기 다음 페이지 로드 실패: \(error.localizedDescription)")
        }
    }
    
    /// 메모리 캐시 클리어 (로그아웃 시 사용)
    func clearCache() {
        repository.clearMemoryCache()
        hasLoadedInitialData = false
        DispatchQueue.main.async {
            self.itemVMs = []
        }
    }
    
    /// 아이템 삭제 (UI에서 즉시 제거)
    func removeItem(with id: String) {
        if let index = itemVMs.firstIndex(where: { $0.id == id }) {
            itemVMs.remove(at: index)
                    debugPrint("✅ HomeView에서 아이템 제거 완료: \(id)")
    }
    
    /// 태그 편집 완료 후 데이터 새로고침
    func refreshAfterTagEdit() async {
        debugPrint("🔄 태그 편집 완료 - 홈 데이터 새로고침 시작")
        
        let isGuest = AccountStorage.shared.isGuest ?? true
        
        if isGuest {
            // 게스트 모드: 로컬에서 다시 로드
            loadScreenshotFromLocal()
        } else {
            // 로그인 모드: 서버에서 다시 로드
            await refreshFromServer()
        }
        
        // 즐겨찾기도 새로고침
        await loadFavorite()
        
        debugPrint("✅ 태그 편집 완료 - 홈 데이터 새로고침 완료")
    }
    
    /// 서버에서 데이터 새로고침 (기존 데이터 교체)
    func refreshFromServer() async {
        debugPrint("🔄 서버에서 데이터 새로고침")
        
        // 페이지와 상태 초기화
        page = 0
        canLoadMorePages = true
        
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
            
            // 메인 스레드에서 UI 업데이트
            await MainActor.run {
                self.itemVMs = uniqueItems
                debugPrint("✅ 서버 새로고침 완료: \(uniqueItems.count)개 (중복 \(serverItems.count - uniqueItems.count)개 제거)")
            }
            
            page += 1
        } catch {
            debugPrint("❌ 서버 새로고침 실패: \(error.localizedDescription)")
        }
    }
}
    
    func delete(_ viewModel: ScreenshotItemViewModel) {
        // 1) 서버·로컬 삭제 호출
        Task {
            try? await viewModel.delete()
            // 2) 리스트에서 제거
            removeItem(with: viewModel.id)
        }
    }
    
    // Carousel 등에서 index 변경 시 호출
    func onAssetChanged(to index: Int) {
        // index 범위 체크
        guard index >= 0 && index < favoriteItemVMs.count else { return }
        
        currentFavoriteIndex = index
        
        // pagination 체크: currentFavoriteIndex가 favoriteItemVMs.count보다 3 적으면 다음 페이지 로드
        let threshold = favoriteItemVMs.count - 3
        if index >= threshold && !isLoadingFavoritePage && canLoadMoreFavoritePages {
            Task {
                await loadNextFavoritePage()
            }
        }
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationObservers() {
        // 즐겨찾기 상태 변경 알림
        NotificationCenter.default.publisher(for: .favoriteStatusChanged)
            .compactMap { notification in
                notification.userInfo?["favoriteInfo"] as? FavoriteStatusInfo
            }
            .sink { [weak self] favoriteInfo in
                self?.updateFavoriteStatus(favoriteInfo)
            }
            .store(in: &cancellables)
        
        // 태그 편집 완료 알림
        NotificationCenter.default.publisher(for: .tagEditCompleted)
            .sink { [weak self] _ in
                Task {
                    await self?.refreshAfterTagEdit()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateFavoriteStatus(_ favoriteInfo: FavoriteStatusInfo) {
        // itemVMs에서 해당 아이템 찾아서 즐겨찾기 상태 업데이트
        if let itemIndex = itemVMs.firstIndex(where: { $0.id == favoriteInfo.imageId }) {
            itemVMs[itemIndex].isFavorite = favoriteInfo.isFavorite
            debugPrint("✅ HomeView - 즐겨찾기 상태 업데이트: \(favoriteInfo.imageId) -> \(favoriteInfo.isFavorite)")
        }
        
        // favoriteItemVMs에서 해당 아이템 처리
        if let favoriteIndex = favoriteItemVMs.firstIndex(where: { $0.id == favoriteInfo.imageId }) {
            if favoriteInfo.isFavorite {
                // 즐겨찾기로 설정됨 - 상태만 업데이트
                favoriteItemVMs[favoriteIndex].isFavorite = true
                debugPrint("✅ HomeView Carousel - 즐겨찾기 상태 업데이트: \(favoriteInfo.imageId)")
            } else {
                // 즐겨찾기 해제됨 - carousel에서 제거
                favoriteItemVMs.remove(at: favoriteIndex)
                
                // currentFavoriteIndex 조정
                if currentFavoriteIndex >= favoriteItemVMs.count && !favoriteItemVMs.isEmpty {
                    currentFavoriteIndex = favoriteItemVMs.count - 1
                } else if favoriteItemVMs.isEmpty {
                    currentFavoriteIndex = 0
                }
                
                debugPrint("✅ HomeView Carousel - 즐겨찾기 아이템 제거: \(favoriteInfo.imageId)")
            }
        } else if favoriteInfo.isFavorite {
            // 새로 즐겨찾기로 추가된 아이템 - favoriteItemVMs에 추가할 수도 있지만,
            // 실제로는 서버에서 최신 즐겨찾기 목록을 다시 로드하는 것이 더 안전함
            Task {
                await loadFavorite()
            }
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
