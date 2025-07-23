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
    @Published var isLoadingPage = false
    @Published var isInitialLoading = false
    private var canLoadMorePages = true
    private var page: Int = 0
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
                self.itemVMs += serverItems
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
            
            // ✅ @MainActor에서 직접 동기적 업데이트
            self.itemVMs = serverItems
        } catch {
            debugPrint("❌ 서버 로드 실패: \(error.localizedDescription)")
            // 서버 실패 시 빈 배열 (로컬 데이터 사용 X)
            self.itemVMs = []
        }
        page += 1
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
    }
    
    func delete(_ viewModel: ScreenshotItemViewModel) {
        // 1) 서버·로컬 삭제 호출
        Task {
            try? await viewModel.delete()
            // 2) 리스트에서 제거
            removeItem(with: viewModel.id)
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
