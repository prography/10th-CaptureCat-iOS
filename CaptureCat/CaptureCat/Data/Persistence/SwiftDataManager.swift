//
//  SwiftDataManager.swift
//  CaptureCat
//
//  Created by minsong kim on 7/14/25.
//

import SwiftData
import Foundation

@MainActor
final class SwiftDataManager {
    static let shared = SwiftDataManager()
    
    var modelContainer: ModelContainer {
        container
    }
    private var _container: ModelContainer?
    private var _context: ModelContext?
    
    private var container: ModelContainer {
        if let container = _container {
            return container
        }
        let schema = Schema([Screenshot.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            _container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("❌ ModelContainer 초기화 실패: \(error)")
        }
        return _container!
    }
    
    private var context: ModelContext {
        if let context = _context {
            return context
        }
        _context = ModelContext(container)
        return _context!
    }
    
    // MARK: Fetch
    
    func fetchAllEntities() throws -> [Screenshot] {
        let desc = FetchDescriptor<Screenshot>()
        return try context.fetch(desc)
    }
    
    func fetchEntity(id: String) -> Screenshot? {
        let pred = #Predicate<Screenshot> { $0.id == id }
        
        do {
            let item = try context.fetch(FetchDescriptor(predicate: pred)).first
            
            return item
        } catch {
            print("🐞 로컬에서 엔티티 가져오는 중 에러: ", error.localizedDescription)
        }
        
        return nil
    }
    
    // MARK: CRUD Upsert/Delete
    
    func upsert(item: ScreenshotItem) throws {
        if let screenshot = fetchEntity(id: item.id) {
            screenshot.fileName = item.fileName
            screenshot.createDate = item.createDate
            screenshot.tags = item.tags
            screenshot.isFavorite = item.isFavorite
        } else {
            let screenshot = Screenshot(
                id: item.id,
                fileName: item.fileName,
                createDate: item.createDate,
                tags: item.tags,
                isFavorite: item.isFavorite
            )
            context.insert(screenshot)
        }
        try context.save()
    }
    
    func delete(id: String) throws {
        guard let screenshot = fetchEntity(id: id) else {
            return
        }
        context.delete(screenshot)
        try context.save()
    }
    
    // 전체 초기화
    func deleteAllScreenshots() throws {
        // 1) 모든 엔티티를 조회
        let allScreenshots = try fetchAllEntities()
        
        // 2) 하나씩 삭제
        for screenshot in allScreenshots {
            context.delete(screenshot)
        }
        
        // 3) 변경사항 저장
        try context.save()
    }
}

extension SwiftDataManager {
    /// 전체 태그 목록 (중복 제거)
    func fetchAllTags() throws -> [String] {
        let all = try fetchAllEntities().flatMap { $0.tags }
        return Array(Set(all)).sorted()
    }
    
    /// 특정 태그를 포함하는 Screenshot 엔티티들을 가져오기
    func fetchEntitiesByTag(_ tag: String) throws -> [Screenshot] {
        let pred = #Predicate<Screenshot> { screenshot in
            screenshot.tagsJSON.contains("\"\(tag)\"")
        }
        let descriptor = FetchDescriptor(predicate: pred)
        return try context.fetch(descriptor)
    }
    
    /// 여러 아이템에 태그 일괄 추가
    func addTag(_ tag: String, toIDs ids: [String]) throws {
        let items = ids.compactMap {
            fetchEntity(id: $0)
        }
        
        for item in items {
            if !item.tags.contains(tag) {
                item.tags.append(tag)
            }
        }
        
        debugPrint("✅ SwifData 아이템에 태그 추가 성공!")
        try context.save()
    }
    
    /// 여러 아이템에서 태그 일괄 삭제
    func removeTag(_ tag: String, fromIDs ids: [String]) throws {
        let items = ids.compactMap { fetchEntity(id: $0) }
        for item in items {
            item.tags.removeAll { $0 == tag }
        }
        try context.save()
    }
    
    /// 전체 아이템에서 태그 이름 변경
    func renameTag(from oldName: String, to newName: String) throws {
        let items = try fetchAllEntities()
        for item in items {
            if item.tags.contains(oldName) {
                item.tags = item.tags.map { $0 == oldName ? newName : $0 }
            }
        }
        try context.save()
    }
}
