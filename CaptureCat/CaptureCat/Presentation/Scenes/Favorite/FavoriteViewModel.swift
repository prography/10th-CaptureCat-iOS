//
//  FavoriteViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import SwiftUI
import Combine

@MainActor
class FavoriteViewModel: ObservableObject {
    // MARK: - Dependencies
    private let repository = ScreenshotRepository.shared
    
    // MARK: - Published Properties
    @Published var favoriteItems: [ScreenshotItemViewModel] = []
    @Published var isLoading = false
    @Published var isLoadingPage = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var page: Int = 0
    private var canLoadMorePages = true
    private var hasLoadedInitialData = false
    private let pageSize = 20
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init() {
        setupNotificationObservers()
    }
    
    // MARK: - Public Methods
    
    /// 즐겨찾기 아이템들 초기 로드
    func loadFavoriteItems() async {
        guard !hasLoadedInitialData else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let items = try await repository.loadFavorites(page: 0, size: pageSize)
            
            // 중복 제거
            var uniqueItems: [ScreenshotItemViewModel] = []
            var seenIDs: Set<String> = []
            
            for item in items {
                if !seenIDs.contains(item.id) {
                    seenIDs.insert(item.id)
                    uniqueItems.append(item)
                }
            }
            
            self.favoriteItems = uniqueItems
            self.page = 1 // 다음 페이지 준비
            self.canLoadMorePages = !items.isEmpty
            self.hasLoadedInitialData = true
            
            debugPrint("✅ 즐겨찾기 초기 로드 완료: \(uniqueItems.count)개")
            
        } catch {
            debugPrint("❌ 즐겨찾기 로드 실패: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
            self.favoriteItems = []
        }
    }
    
    /// 다음 페이지 로드 (페이지네이션)
    func loadNextPage() async {
        guard !isLoadingPage, canLoadMorePages else { return }
        
        isLoadingPage = true
        defer { isLoadingPage = false }
        
        do {
            let newItems = try await repository.loadFavorites(page: page, size: pageSize)
            
            if newItems.isEmpty {
                canLoadMorePages = false
                debugPrint("⚠️ 더 이상 로드할 즐겨찾기 아이템이 없습니다.")
            } else {
                // 중복 제거: 기존 ID와 겹치지 않는 아이템만 추가
                let existingIDs = Set(self.favoriteItems.map { $0.id })
                let uniqueNewItems = newItems.filter { !existingIDs.contains($0.id) }
                
                if !uniqueNewItems.isEmpty {
                    self.favoriteItems += uniqueNewItems
                    debugPrint("✅ 새로운 즐겨찾기 아이템 \(uniqueNewItems.count)개 추가")
                } else {
                    debugPrint("⚠️ 모든 즐겨찾기 아이템이 중복이므로 추가하지 않음")
                }
                
                page += 1
            }
            
        } catch {
            debugPrint("❌ 즐겨찾기 다음 페이지 로드 실패: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    /// 새로고침 (Pull to Refresh)
    func refreshFavoriteItems() async {
        hasLoadedInitialData = false
        page = 0
        canLoadMorePages = true
        favoriteItems = []
        errorMessage = nil
        
        await loadFavoriteItems()
    }
    
    /// 즐겨찾기에서 아이템 제거 (UI에서 즉시 제거)
    func removeItem(with id: String) {
        if let index = favoriteItems.firstIndex(where: { $0.id == id }) {
            favoriteItems.remove(at: index)
            debugPrint("✅ 즐겨찾기에서 아이템 제거 완료: \(id)")
        }
    }
    
    /// 아이템 삭제 (즐겨찾기 토글)
    func toggleFavorite(_ viewModel: ScreenshotItemViewModel) {
        // 즐겨찾기 페이지에서는 즐겨찾기 해제만 가능하므로, 즉시 UI에서 제거
        removeItem(with: viewModel.id)
        
        Task {
            do {
                // 🔧 Repository의 deleteFavorite를 직접 호출 (항상 삭제만 수행)
                try await ScreenshotRepository.shared.deleteFavorite(id: viewModel.id)
                
                // ✅ API 성공 시 ViewModel의 isFavorite 상태 업데이트
                await MainActor.run {
                    viewModel.isFavorite = false
                }
                
                debugPrint("✅ 즐겨찾기에서 제거 완료: \(viewModel.id)")
                
                // 성공 시 다른 뷰들에게 상태 변경 알림
                let favoriteInfo = FavoriteStatusInfo(imageId: viewModel.id, isFavorite: false)
                NotificationCenter.default.post(
                    name: .favoriteStatusChanged,
                    object: nil,
                    userInfo: ["favoriteInfo": favoriteInfo]
                )
                
            } catch {
                debugPrint("❌ 즐겨찾기 삭제 실패: \(error.localizedDescription)")
                self.errorMessage = error.localizedDescription
                
                // 🔄 에러 발생 시 아이템을 다시 추가 (롤백)
                self.favoriteItems.append(viewModel)
                debugPrint("🔄 에러로 인해 아이템 롤백: \(viewModel.id)")
            }
        }
    }
    
    /// 로딩 상태 체크 (페이지네이션 트리거용)
    func shouldLoadNextPage(for index: Int) -> Bool {
        let threshold = max(0, favoriteItems.count - 3)
        return index >= threshold && !isLoadingPage && canLoadMorePages
    }
    
    /// 에러 메시지 초기화
    func clearErrorMessage() {
        errorMessage = nil
    }
    
    // MARK: - Notification Handling
    
    private func setupNotificationObservers() {
        NotificationCenter.default.publisher(for: .favoriteStatusChanged)
            .compactMap { notification in
                notification.userInfo?["favoriteInfo"] as? FavoriteStatusInfo
            }
            .sink { [weak self] favoriteInfo in
                self?.updateFavoriteStatus(favoriteInfo)
            }
            .store(in: &cancellables)
    }
    
    private func updateFavoriteStatus(_ favoriteInfo: FavoriteStatusInfo) {
        if favoriteInfo.isFavorite {
            // 즐겨찾기로 추가됨 - 상태만 업데이트 (이미 즐겨찾기 페이지에 있다면)
            if let itemIndex = favoriteItems.firstIndex(where: { $0.id == favoriteInfo.imageId }) {
                favoriteItems[itemIndex].isFavorite = true
                debugPrint("✅ FavoriteView - 즐겨찾기 상태 업데이트: \(favoriteInfo.imageId)")
            }
            // 새로 추가된 아이템은 다음 로드 시에 포함될 것이므로 별도 처리 안함
        } else {
            // 즐겨찾기 해제됨 - 즐겨찾기 목록에서 제거
            if let itemIndex = favoriteItems.firstIndex(where: { $0.id == favoriteInfo.imageId }) {
                favoriteItems.remove(at: itemIndex)
                debugPrint("✅ FavoriteView - 즐겨찾기 아이템 제거: \(favoriteInfo.imageId)")
            }
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
