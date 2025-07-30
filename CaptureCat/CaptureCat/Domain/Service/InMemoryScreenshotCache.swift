//
//  InMemoryScreenshotCache.swift
//  CaptureCat
//
//  Created by minsong kim on 7/25/25.
//

import Foundation

/// 로그인 모드에서 사용하는 메모리 기반 스크린샷 캐시
@MainActor
final class InMemoryScreenshotCache {
    static let shared = InMemoryScreenshotCache()
    
    private var cache: [String: ScreenshotItemViewModel] = [:]
    private var allItems: [ScreenshotItemViewModel] = []
    
    private init() {}
    
    // MARK: - Cache Operations
    
    func store(_ item: ScreenshotItemViewModel) {
        cache[item.id] = item
        
        // allItems 배열도 업데이트
        if let index = allItems.firstIndex(where: { $0.id == item.id }) {
            allItems[index] = item
        } else {
            allItems.append(item)
        }
    }
    
    func store(_ items: [ScreenshotItemViewModel]) {
        for item in items {
            cache[item.id] = item
        }
        allItems = items
    }
    
    func retrieve(id: String) -> ScreenshotItemViewModel? {
        return cache[id]
    }
    
    func retrieveAll() -> [ScreenshotItemViewModel] {
        return allItems
    }
    
    func remove(id: String) {
        cache.removeValue(forKey: id)
        allItems.removeAll { $0.id == id }
    }
    
    func clear() {
        cache.removeAll()
        allItems.removeAll()
    }
    
    // MARK: - Tag Operations
    
    func getItemsByTag(_ tag: String) -> [ScreenshotItemViewModel] {
        return allItems.filter { item in
            item.tags.contains { $0.name == tag }
        }
    }
    
    func getItemsByTags(_ tags: [String]) -> [ScreenshotItemViewModel] {
        return allItems.filter { item in
            let itemTagNames = item.tags.map { $0.name }
            return tags.allSatisfy { tag in itemTagNames.contains(tag) }
        }
    }
    
    func getAllTags() -> [String] {
        let allTags = allItems.flatMap { $0.tags.map { $0.name } }
        return Array(Set(allTags)).sorted()
    }
    
    func getOtherTags(for baseTags: [String]) -> [String] {
        let matchingItems = getItemsByTags(baseTags)
        let otherTags = matchingItems.flatMap { $0.tags.map { $0.name } }.filter { !baseTags.contains($0) }
        return Array(Set(otherTags)).sorted()
    }
    
    // MARK: - Favorite Operations
    
    /// 특정 아이템의 즐겨찾기 상태 업데이트
    func updateFavorite(id: String, isFavorite: Bool) {
        cache[id]?.isFavorite = isFavorite
        
        if let index = allItems.firstIndex(where: { $0.id == id }) {
            allItems[index].isFavorite = isFavorite
        }
    }
    
    /// 즐겨찾기 상태인 아이템들만 반환
    func getFavorites() -> [ScreenshotItemViewModel] {
        return allItems.filter { $0.isFavorite }
    }
}
