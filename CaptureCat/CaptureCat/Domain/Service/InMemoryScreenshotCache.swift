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
        return allItems.filter { $0.tags.contains(tag) }
    }
    
    func getItemsByTags(_ tags: [String]) -> [ScreenshotItemViewModel] {
        return allItems.filter { item in
            tags.allSatisfy { tag in item.tags.contains(tag) }
        }
    }
    
    func getAllTags() -> [String] {
        let allTags = allItems.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
    
    func getOtherTags(for baseTags: [String]) -> [String] {
        let matchingItems = getItemsByTags(baseTags)
        let otherTags = matchingItems.flatMap { $0.tags }.filter { !baseTags.contains($0) }
        return Array(Set(otherTags)).sorted()
    }
}
