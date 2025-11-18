//
//  AppDataResetter.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import Foundation

protocol AppDataResetting {
    func resetAll()
}

@MainActor
final class AppDataResetter: AppDataResetting {
    private let repository: ScreenshotRepository
    
    init(repository: ScreenshotRepository) {
        self.repository = repository
    }
    
    func resetAll() {
        clearAllCacheData()
        clearUserDefaults()
    }
    
    private func clearAllCacheData() {
        repository.clearMemoryCache()
        PhotoLoader.shared.clearAllCache()
        do {
            try SwiftDataManager.shared.deleteAllScreenshots()
        } catch {
            debugPrint("⚠️ SwiftData 정리 실패: \(error.localizedDescription)")
        }
    }
    
    private func clearUserDefaults() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: LocalUserKeys.selectedTopics.rawValue)
        defaults.removeObject(forKey: LocalUserKeys.deleteOriginalsAfterSave.rawValue)
        defaults.removeObject(forKey: LocalUserKeys.taggedImageIds.rawValue)
        defaults.removeObject(forKey: LocalUserKeys.didImageDeleteBottomSheetPresented.rawValue)
        defaults.synchronize()
    }
}
