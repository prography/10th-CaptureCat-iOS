//
//  ScreenshotRepository.swift
//  CaptureCat
//
//  Created by minsong kim on 7/20/25.
//

import Foundation

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
        imageData: Data(),//실제 로딩은 ViewModel 안 PhotoLoader로
        fileName: ent.fileName,
        createDate: ent.createDate,
        tags: ent.tags.compactMap { $0.value },
        isFavorite: ent.isFavorite
      )
    }
    return items.map(viewModel(for:))
  }
    
    func fetchViewModels(for ids: [String]) -> [ScreenshotItemViewModel] {
        return ids.compactMap { self.vms[$0] }
    }

  func viewModel(for model: ScreenshotItem) -> ScreenshotItemViewModel {
      if let ex = vms[model.id] {
          return ex
      }
    let viewModel = ScreenshotItemViewModel(model: model)
    vms[model.id] = viewModel
    return viewModel
  }

  // MARK: Tag Orchestration

  func fetchAllTags() throws -> [String] {
    // 로컬 우선
    try SwiftDataManager.shared.fetchAllTags()
  }

  func addTag(_ tag: String, toIDs ids: [String]) async throws {
    // 1) 로컬
    try SwiftDataManager.shared.addTag(tag, toIDs: ids)
    // 2) 서버
    try await ScreenshotService.shared.addTag(tag, toIDs: ids)
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
