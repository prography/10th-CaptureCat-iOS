//
//  ScreenshotItemViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/20/25.
//

import SwiftUI
import UIKit

@MainActor
class ScreenshotItemViewModel: ObservableObject, Identifiable {
    // MARK: – Properties
    let id: String
    @Published var fileName: String
    @Published var createDate: Date
    @Published var thumbnail: UIImage?
    @Published var fullImage: UIImage?
    @Published var isLoadingImage = false
    @Published var tags: [String]
    @Published var isFavorite: Bool
    @Published var isSaving = false
    @Published var errorMessage: String?
    
    private var saveWorkItem: DispatchWorkItem?
    
    // MARK: – Init
    init(model: ScreenshotItem) {
        self.id = model.id
        self.fileName   = model.fileName
        self.createDate = model.createDate
        self.tags       = model.tags
        self.isFavorite = model.isFavorite
    }
    
    // MARK: – Image Loading
    func loadThumbnail(size: CGSize) async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        thumbnail = await PhotoLoader.shared.requestImage(
            id: id,
            targetSize: size
        )
    }
    
    func loadFullImage() async {
        isLoadingImage = true
        defer { isLoadingImage = false }
        fullImage = await PhotoLoader.shared.requestFullImage(id: id)
    }
    
    // MARK: – User Actions
    func toggleFavorite() {
        isFavorite.toggle()
        scheduleSave()
    }
    
    func addTag(_ tag: String) {
        guard !tags.contains(tag) else { return }
        tags.append(tag)
        scheduleSave()
    }
    
    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
        scheduleSave()
    }
    
    // MARK: – Debounced Save
    private func scheduleSave() {
        saveWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            Task { await self?.saveChanges() }
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }
    
    // MARK: – Persistence & Sync
    func saveChanges() async {
        isSaving = true
        defer { isSaving = false }
        
        let item = ScreenshotItem(
            id: id,
            imageData: Data(), // imageData handled by PhotoLoader
            fileName: fileName,
            createDate: createDate,
            tags: tags,
            isFavorite: isFavorite
        )
        
        do {
            if AccountStorage.shared.isGuest ?? true {
                try SwiftDataManager.shared.upsert(item: item)
            } else {
                // 2) 서버 업로드 (응답 DTO 무시하거나 처리)
                let dto = item.toDTO()
                _ = try await ScreenshotService.shared.upload(dto)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: – Delete
    func delete() async throws {
        // 1) 서버에서 삭제
        try await ScreenshotService.shared.delete(id: id)
        // 2) 로컬에서 삭제
        try SwiftDataManager.shared.delete(id: id)
    }
    
    // MARK: – DTO Mapping
    func toDTO() -> PhotoDTO {
        PhotoDTO(
            id: id,
            fileName: fileName,
            createDate: createDate,
            tags: tags,
            isFavorite: isFavorite,
            imageData: thumbnail?.jpegData(compressionQuality: 0.8)
        )
    }
}
