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
//    @Published var items: [ScreenshotItem] = []
    
    // MARK: - Dependencies
    private let repository = ScreenshotRepository.shared
    @Published var itemVMs: [ScreenshotItemViewModel] = []
    
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
    
    func loadScreenshotFromLocal() {
        debugPrint("📱 로컬 데이터 로드 시작...")
        
        do {
            let localItems = try ScreenshotRepository.shared.loadAll()
            self.itemVMs = localItems
            
            debugPrint("✅ 로컬 데이터 로드 완료: \(localItems.count)개 항목")
            for (index, item) in localItems.enumerated() {
                debugPrint("🔍 - 로컬 아이템[\(index)]: ID=\(item.id), 파일명=\(item.fileName)")
            }
        } catch {
            debugPrint("❌ loadScreenshotFromLocal Error: \(error.localizedDescription)")
            self.itemVMs = []
        }
    }
    
    /// 스마트 로딩 (로그인 상태에 따라 자동 분기)
    func loadScreenshots() async {
        let isGuest = AccountStorage.shared.isGuest ?? true
        debugPrint("🔍 HomeViewModel 로딩 모드 확인:")
        debugPrint("🔍 - AccountStorage.shared.isGuest: \(AccountStorage.shared.isGuest?.description ?? "nil")")
        debugPrint("🔍 - 최종 게스트 여부: \(isGuest)")
        
        if isGuest {
            // 게스트 모드: 로컬에서만 로드
            debugPrint("👤 게스트 모드: 로컬 데이터 로드")
            loadScreenshotFromLocal()
        } else {
            // 로그인 모드: 서버에서만 로드
            debugPrint("🔐 로그인 모드: 서버 데이터 로드")
            await loadFromServerOnly()
        }
    }
    
    /// 서버에서만 로드 (로그인 모드)
    func loadFromServerOnly() async {
        debugPrint("🔄 서버에서 데이터 로드 시작...")
        
        do {
            let serverItems = try await repository.loadFromServerOnly()
            
            debugPrint("🔍 서버에서 받은 아이템 개수: \(serverItems.count)")
            for (index, item) in serverItems.enumerated() {
                debugPrint("🔍 - 아이템[\(index)]: ID=\(item.id), URL=\(item.imageURL ?? "없음")")
            }
            
            // ✅ @MainActor에서 직접 동기적 업데이트
            self.itemVMs = serverItems
            debugPrint("✅ HomeViewModel.itemVMs 업데이트 완료: \(self.itemVMs.count)개")
            
            debugPrint("✅ 서버 전용 로드 완료: \(serverItems.count)개 항목")
        } catch {
            debugPrint("❌ 서버 로드 실패: \(error.localizedDescription)")
            
            // 서버 실패 시 빈 배열 (로컬 데이터 사용 X)
            self.itemVMs = []
        }
    }
    
    /// 선택된 스크린샷들을 서버에만 업로드 (로그인 모드)
    func uploadToServerOnly(_ selectedItems: [ScreenshotItemViewModel]) async {
        guard !(AccountStorage.shared.isGuest ?? true) else {
            debugPrint("⚠️ 게스트 모드에서는 서버 업로드를 사용할 수 없습니다.")
            return
        }
        
        do {
            try await repository.uploadToServerOnly(viewModels: selectedItems)
            debugPrint("✅ 서버 전용 업로드 완료")
        } catch {
            debugPrint("❌ 서버 업로드 실패: \(error.localizedDescription)")
        }
    }
    
    /// 메모리 캐시 클리어 (로그아웃 시 사용)
    func clearCache() {
        repository.clearMemoryCache()
        DispatchQueue.main.async {
            self.itemVMs = []
        }
    }
    
    func delete(_ vm: ScreenshotItemViewModel) {
        // 1) 서버·로컬 삭제 호출
        Task {
            try? await vm.delete()
            // 2) 리스트에서 제거
            if let idx = itemVMs.firstIndex(where: { $0.id == vm.id }) {
                itemVMs.remove(at: idx)
            }
        }
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}
