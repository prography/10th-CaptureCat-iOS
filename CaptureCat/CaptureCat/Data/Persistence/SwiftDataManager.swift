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
            screenshot.tags = item.getTagNames()  // Tag 배열을 String 배열로 변환
            screenshot.isFavorite = item.isFavorite
        } else {
            let screenshot = Screenshot(
                id: item.id,
                fileName: item.fileName,
                createDate: item.createDate,
                tags: item.getTagNames(),  // Tag 배열을 String 배열로 변환
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
    /// 전체 태그 목록 (중복 제거) - String 배열 반환
    func fetchAllTags() throws -> [String] {
        let all = try fetchAllEntities().flatMap { $0.tags }
        return Array(Set(all)).sorted()
    }
    
    /// 전체 태그 목록 (중복 제거) - Tag 객체 배열 반환
    func fetchAllTagsAsTag() throws -> [Tag] {
        let tagNames = try fetchAllTags()
        // 로컬 데이터는 ID가 없으므로 임시 ID 생성 (해시 기반으로 일관성 보장)
        return tagNames.enumerated().map { index, name in
            Tag(id: name.hashValue, name: name)
        }
    }
    
    /// 특정 태그를 포함하는 Screenshot 엔티티들을 가져오기
    func fetchEntitiesByTag(_ tag: String) throws -> [Screenshot] {
        let pred = #Predicate<Screenshot> { screenshot in
            screenshot.tagsJSON.contains("\"\(tag)\"")
        }
        let descriptor = FetchDescriptor(predicate: pred)
        return try context.fetch(descriptor)
    }
    
    /// 여러 태그를 모두 포함하는 Screenshot 엔티티들을 가져오기
    func fetchEntitiesByTags(_ tags: [String]) throws -> [Screenshot] {
        // 빈 배열이면 모든 엔티티 반환
        guard !tags.isEmpty else {
            return try fetchAllEntities()
        }
        
        // 각 태그를 모두 포함하는 엔티티들을 필터링
        let allEntities = try fetchAllEntities()
        return allEntities.filter { screenshot in
            let screenshotTags = screenshot.tags
            return tags.allSatisfy { tag in
                screenshotTags.contains(tag)
            }
        }
    }
    
    /// 특정 태그들을 모두 포함하는 스크린샷들에서 그 외의 태그들을 반환
    func fetchOtherTagsFromScreenshotsContaining(_ tags: [String]) throws -> [String] {
        // 입력된 태그들을 모두 포함하는 스크린샷들 찾기
        let matchingScreenshots = try fetchEntitiesByTags(tags)
        
        // 각 스크린샷에서 입력된 태그들을 제외한 나머지 태그들 수집
        var otherTags: Set<String> = []
        
        for screenshot in matchingScreenshots {
            let screenshotTags = screenshot.tags
            let remainingTags = screenshotTags.filter { !tags.contains($0) }
            otherTags.formUnion(remainingTags)
        }
        
        // 정렬된 배열로 반환
        return Array(otherTags).sorted()
    }
    
    func fetchOtherTagsFromScreenshotsContainingAsTag(_ tags: [String]) throws -> [Tag] {
        // String 태그들을 먼저 가져오기
        let stringTags = try fetchOtherTagsFromScreenshotsContaining(tags)
        
        // String 태그를 Tag 객체로 변환 (해시 기반 ID 사용)
        return stringTags.map { tagName in
            Tag(id: tagName.hashValue, name: tagName)
        }
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
    
    func updateTag(id: String, tags: [String]) throws {
        let item = fetchEntity(id: id)
        item?.tags = tags
        try context.save()
    }
    
    func deleteTag(imageId: String, tagId: String) throws {
        let item = fetchEntity(id: imageId)
        item?.tags.remove(at: Int(tagId) ?? 0)
        try context.save()
    }
}

// MARK: - Favorite Management
extension SwiftDataManager {
    /// 특정 이미지의 즐겨찾기 상태 설정
    func setFavorite(imageId: String, isFavorite: Bool) throws {
        guard let item = fetchEntity(id: imageId) else {
            debugPrint("⚠️ 이미지 ID를 찾을 수 없음: \(imageId)")
            return
        }
        
        item.isFavorite = isFavorite
        try context.save()
        
        debugPrint("✅ 즐겨찾기 상태 변경 완료: \(imageId) -> \(isFavorite)")
    }
    
    /// 특정 이미지의 즐겨찾기 상태 토글
    func toggleFavorite(imageId: String) throws {
        guard let item = fetchEntity(id: imageId) else {
            debugPrint("⚠️ 이미지 ID를 찾을 수 없음: \(imageId)")
            return
        }
        
        item.isFavorite.toggle()
        try context.save()
        
        debugPrint("✅ 즐겨찾기 상태 토글 완료: \(imageId) -> \(item.isFavorite)")
    }
    
    /// 즐겨찾기에 추가
    func addToFavorites(imageId: String) throws {
        try setFavorite(imageId: imageId, isFavorite: true)
    }
    
    /// 즐겨찾기에서 제거
    func removeFromFavorites(imageId: String) throws {
        try setFavorite(imageId: imageId, isFavorite: false)
    }
    
    /// 즐겨찾기 상태인 모든 엔티티 가져오기
    func fetchFavoriteEntities() throws -> [Screenshot] {
        let pred = #Predicate<Screenshot> { $0.isFavorite == true }
        let descriptor = FetchDescriptor(predicate: pred)
        return try context.fetch(descriptor)
    }
    
    /// 특정 이미지의 즐겨찾기 상태 조회
    func isFavorite(imageId: String) -> Bool {
        guard let item = fetchEntity(id: imageId) else {
            return false
        }
        return item.isFavorite
    }
    
    /// 여러 이미지의 즐겨찾기 상태 일괄 설정
    func setFavorites(imageIds: [String], isFavorite: Bool) throws {
        let items = imageIds.compactMap { fetchEntity(id: $0) }
        
        for item in items {
            item.isFavorite = isFavorite
        }
        
        try context.save()
        debugPrint("✅ 다중 즐겨찾기 상태 변경 완료: \(imageIds.count)개 -> \(isFavorite)")
    }
    
    /// 즐겨찾기 개수 조회
    func getFavoriteCount() throws -> Int {
        let favorites = try fetchFavoriteEntities()
        return favorites.count
    }
}
