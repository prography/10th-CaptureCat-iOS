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
                // 게스트 모드: 로컬 전용 저장
                try SwiftDataManager.shared.upsert(item: item)
                debugPrint("✅ 로컬 전용 저장 완료: \(fileName)")
            } else {
                // 로그인 모드: 서버 전용 저장 (로컬 저장 X)
                try await ScreenshotRepository.shared.saveToServerOnly(self)
                debugPrint("✅ 서버 전용 저장 완료: \(fileName)")
            }
            
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("❌ 저장 실패: \(error.localizedDescription)")
        }
    }
    
    /// 로컬에만 저장 (게스트 모드 전용)
    func saveToLocal() async {
        guard AccountStorage.shared.isGuest ?? true else {
            debugPrint("⚠️ 로그인 모드에서는 로컬 저장을 사용할 수 없습니다.")
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        let item = ScreenshotItem(
            id: id,
            imageData: Data(),
            fileName: fileName,
            createDate: createDate,
            tags: tags,
            isFavorite: isFavorite
        )
        
        do {
            try SwiftDataManager.shared.upsert(item: item)
            debugPrint("✅ 로컬 저장 완료: \(fileName)")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("❌ 로컬 저장 실패: \(error.localizedDescription)")
        }
    }
    
    /// 서버에만 저장 (로그인 모드 전용)
    func saveToServer() async {
        guard !(AccountStorage.shared.isGuest ?? true) else {
            debugPrint("⚠️ 게스트 모드에서는 서버 저장을 사용할 수 없습니다.")
            return
        }
        
        isSaving = true
        defer { isSaving = false }
        
        do {
            try await ScreenshotRepository.shared.saveToServerOnly(self)
            debugPrint("✅ 서버 저장 완료: \(fileName)")
        } catch {
            errorMessage = error.localizedDescription
            debugPrint("❌ 서버 저장 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: – Delete
    func delete() async throws {
        // 1) 서버에서 삭제
//        try await ScreenshotService.shared.delete(id: id)
        // 2) 로컬에서 삭제
        if AccountStorage.shared.isGuest ?? true {
            try SwiftDataManager.shared.delete(id: id)
        }
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
