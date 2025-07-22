//
//  ScreenshotRepository.swift
//  CaptureCat
//
//  Created by minsong kim on 7/20/25.
//

import Foundation
import Photos

@MainActor
final class ScreenshotRepository {
    static let shared = ScreenshotRepository()
    private var vms: [String: ScreenshotItemViewModel] = [:]
    
    private init() {}
    
    /// 로컬에서 불러와 ViewModel 생성/재사용
    func loadAll() throws -> [ScreenshotItemViewModel] {
        let ents = try SwiftDataManager.shared.fetchAllEntities()
        let items = ents.map { ent in
            ScreenshotItem(
                id: ent.id,
                imageData: Data(),
                fileName: ent.fileName,
                createDate: ent.createDate,
                tags: ent.tags,
                isFavorite: ent.isFavorite
            )
        }
        return items.map(viewModel(for:))
    }
    
    /// 특정 태그를 포함하는 ScreenshotItemViewModel 배열 반환
    func loadByTag(_ tag: String) throws -> [ScreenshotItemViewModel] {
        let ents = try SwiftDataManager.shared.fetchEntitiesByTag(tag)
        let items = ents.map { ent in
            ScreenshotItem(
                id: ent.id,
                imageData: Data(),
                fileName: ent.fileName,
                createDate: ent.createDate,
                tags: ent.tags,
                isFavorite: ent.isFavorite
            )
        }
        return items.map(viewModel(for:))
    }
    
    /// 여러 태그를 모두 포함하는 ScreenshotItemViewModel 배열 반환
    func loadByTags(_ tags: [String]) throws -> [ScreenshotItemViewModel] {
        let ents = try SwiftDataManager.shared.fetchEntitiesByTags(tags)
        let items = ents.map { ent in
            ScreenshotItem(
                id: ent.id,
                imageData: Data(),
                fileName: ent.fileName,
                createDate: ent.createDate,
                tags: ent.tags,
                isFavorite: ent.isFavorite
            )
        }
        return items.map(viewModel(for:))
    }
    
    /// 특정 태그들을 모두 포함하는 스크린샷들에서 그 외의 태그들을 반환
    func fetchOtherTagsFromScreenshotsContaining(_ tags: [String]) throws -> [String] {
        return try SwiftDataManager.shared.fetchOtherTagsFromScreenshotsContaining(tags)
    }
    
    func fetchViewModels(for ids: [String]) -> [ScreenshotItemViewModel] {
        return ids.compactMap { self.vms[$0] }
    }
    
    func viewModel(for model: ScreenshotItem) -> ScreenshotItemViewModel {
        if let existingViewModel = vms[model.id] {
            syncViewModel(existingViewModel, with: model)
            return existingViewModel
        }
        let viewModel = ScreenshotItemViewModel(model: model)
        vms[model.id] = viewModel
        return viewModel
    }
    
    private func syncViewModel(_ viewModel: ScreenshotItemViewModel, with model: ScreenshotItem) {
        viewModel.fileName = model.fileName
        viewModel.createDate = model.createDate
        viewModel.tags = model.tags
        viewModel.isFavorite = model.isFavorite
    }
    
    // MARK: Tag Orchestration
    func fetchAllTags() throws -> [String] {
        // 로컬 우선
        try SwiftDataManager.shared.fetchAllTags()
    }
    
    func addTag(_ tag: String, toIDs ids: [String]) async throws {
        if AccountStorage.shared.isGuest ?? true {
            try SwiftDataManager.shared.addTag(tag, toIDs: ids)
        } else {
            try await ScreenshotService.shared.addTag(tag, toIDs: ids)
        }
    }
    
    func removeTag(_ tag: String, fromIDs ids: [String]) async throws {
        try SwiftDataManager.shared.removeTag(tag, fromIDs: ids)
        try await ScreenshotService.shared.removeTag(tag, fromIDs: ids)
    }
    
    func renameTag(from oldName: String, to newName: String) async throws {
        try SwiftDataManager.shared.renameTag(from: oldName, to: newName)
        try await ScreenshotService.shared.renameTag(from: oldName, to: newName)
    }
}
