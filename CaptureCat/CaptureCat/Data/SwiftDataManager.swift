//
//  SwiftDataManager.swift
//  CaptureCat
//
//  Created by minsong kim on 7/14/25.
//

import Foundation
import SwiftData
import Photos

@Observable
final class SwiftDataManager {
    static let shared = SwiftDataManager()
    
    private var _modelContainer: ModelContainer?
    private var _modelContext: ModelContext?
    
    private var modelContainer: ModelContainer {
        if let container = _modelContainer {
            return container
        }
        
        do {
            let schema = Schema([Screenshot.self])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            _modelContainer = container
            return container
        } catch {
            fatalError("SwiftData 초기화 실패: \(error)")
        }
    }
    
    private var modelContext: ModelContext {
        if let context = _modelContext {
            return context
        }
        
        let context = ModelContext(modelContainer)
        _modelContext = context
        return context
    }
    
    private init() {
        // 초기화는 프로퍼티 접근 시점에 지연 처리
    }
    
    var context: ModelContext {
        return modelContext
    }
    
    // MARK: - Save Context
    func save() {
        do {
            try modelContext.save()
            debugPrint("📚 SwiftData에 Tag 저장 완료!!")
        } catch {
            print("❌ SwiftData 저장 실패: \(error)")
        }
    }
}

// MARK: - Screenshot 관련 메서드
extension SwiftDataManager {
    
    // PHAsset을 Screenshot으로 저장
    func saveScreenshot(from asset: PHAsset, isFavorite: Bool, with tags: [String] = []) {
        let screenshot = Screenshot(from: asset, isFavorite: isFavorite, tags: tags)
        modelContext.insert(screenshot)
        save()
    }
    
    // localIdentifier로 Screenshot 찾기
    func fetchScreenshot(with id: String) -> Screenshot? {
        let descriptor = FetchDescriptor<Screenshot>(
            predicate: #Predicate { $0.fileName == id }
        )
        
        do {
            let screenshots = try modelContext.fetch(descriptor)
            return screenshots.first
        } catch {
            print("❌ Screenshot 조회 실패: \(error)")
            return nil
        }
    }
    
    // 모든 Screenshot 조회
    func fetchAllScreenshots() -> [Screenshot] {
        let descriptor = FetchDescriptor<Screenshot>(
//            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ Screenshot 목록 조회 실패: \(error)")
            return []
        }
    }
    
    // 특정 태그가 포함된 Screenshot 조회
    func fetchScreenshots(with tag: String) -> [Screenshot] {
        let descriptor = FetchDescriptor<Screenshot>(
            predicate: #Predicate { screenshot in
                screenshot.tags.contains(tag)
            },
//            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ 태그별 Screenshot 조회 실패: \(error)")
            return []
        }
    }
    
    // 태그가 없는 Screenshot 조회
    func fetchUntaggedScreenshots() -> [Screenshot] {
        let descriptor = FetchDescriptor<Screenshot>(
            predicate: #Predicate { screenshot in
                screenshot.tags.isEmpty
            },
//            sortBy: [SortDescriptor(\.captureDate, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("❌ 태그 없는 Screenshot 조회 실패: \(error)")
            return []
        }
    }
    
    // Screenshot 삭제
    func deleteScreenshot(_ screenshot: Screenshot) {
        modelContext.delete(screenshot)
        save()
    }
}

// MARK: - Tag 관리 메서드
extension SwiftDataManager {
    // 사용된 모든 태그 조회
    func fetchAllUsedTags() -> [String] {
        let screenshots = fetchAllScreenshots()
        var allTags: Set<String> = []
        
        screenshots.forEach { screenshot in
            allTags.formUnion(screenshot.tags)
        }
        
        return Array(allTags).sorted()
    }
    
    // Screenshot에 태그 추가
    func addTag(_ tag: String, to screenshot: Screenshot) {
        if !screenshot.tags.contains(tag) {
            screenshot.tags.append(tag)
            save()
        }
    }
    
    // Screenshot에서 태그 제거
    func removeTag(_ tag: String, from screenshot: Screenshot) {
        screenshot.tags.removeAll { $0 == tag }
        save()
    }
    
    // PHAsset에 태그들을 일괄 추가
    func addTags(_ tags: [String], isFavorite: Bool, to asset: PHAsset) {
        // 기존 Screenshot이 있는지 확인
        if let screenshot = fetchScreenshot(with: asset.localIdentifier) {
            // 기존 태그와 새 태그 합치기 (중복 제거)
            let uniqueNewTags = tags.filter { !screenshot.tags.contains($0) }
            screenshot.tags.append(contentsOf: uniqueNewTags)
        } else {
            // 새 Screenshot 생성
            let screenshot = Screenshot(from: asset, isFavorite: isFavorite,tags: tags)
            modelContext.insert(screenshot)
        }
        save()
    }
    
    // PHAsset의 태그들을 모두 교체
    func replaceTags(_ tags: [String], isFavorite: Bool, for asset: PHAsset) {
        if let screenshot = fetchScreenshot(with: asset.localIdentifier) {
            screenshot.tags = tags
        } else {
            let screenshot = Screenshot(from: asset, isFavorite: isFavorite, tags: tags)
            modelContext.insert(screenshot)
        }
        debugPrint("📚 SwiftData에 Tag 저장 시도 -> PHAsset 태그 전체 교체!!")
        save()
    }
    
    // 태그 이름 변경
    func renameTag(from oldTag: String, to newTag: String) {
        let screenshots = fetchScreenshots(with: oldTag)
        
        screenshots.forEach { screenshot in
            if let index = screenshot.tags.firstIndex(of: oldTag) {
                screenshot.tags[index] = newTag
            }
        }
        
        save()
    }
    
    // 특정 태그를 모든 Screenshot에서 삭제
    func deleteTag(_ tag: String) {
        let screenshots = fetchScreenshots(with: tag)
        
        screenshots.forEach { screenshot in
            screenshot.tags.removeAll { $0 == tag }
        }
        
        save()
    }
} 
