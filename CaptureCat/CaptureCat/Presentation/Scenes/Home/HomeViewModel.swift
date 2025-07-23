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
        do {
            self.itemVMs =  try ScreenshotRepository.shared.loadAll()
        } catch {
            print("🐞 loadScreenshotFromLocal Error: \(error.localizedDescription)")
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
