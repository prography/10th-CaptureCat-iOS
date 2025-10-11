//
//  TagViewModel+TagManagement.swift
//  CaptureCat
//
//  Created by AI Assistant on 1/15/25.
//

import SwiftUI

// MARK: - Tag Management
extension TagViewModel {
    
    // MARK: - Tag Loading & Saving
    /// 전체 태그 목록을 로컬/서버에서 가져와 tags에 세팅
    func loadTags() {
        tags = UserDefaults.standard.selectedTopics
    }
    
    /// 전체 태그 목록을 UserDefaults에 저장
    func saveTags() {
        UserDefaults.standard.selectedTopics = tags
        debugPrint("💾 태그 목록 저장 완료: \(tags)")
    }
    
    // mode 변경이나 asset 변경 시 호출해서 selectedTags 초기화 (안전한 배열 접근)
    func updateSelectedTags() {
        switch mode {
        case .batch:
            selectedTags = batchSelectedTags
        case .single:
            // 안전한 인덱스 접근 (크래시 방지)
            if currentIndex >= 0 && currentIndex < itemVMs.count {
                selectedTags = Set(itemVMs[currentIndex].tags.map { $0.name })
            } else {
                debugPrint("⚠️ updateSelectedTags: 잘못된 currentIndex \(currentIndex) (총 \(itemVMs.count)개)")
                selectedTags = []
                // currentIndex를 안전한 범위로 조정
                if !itemVMs.isEmpty {
                    currentIndex = min(currentIndex, itemVMs.count - 1)
                    currentIndex = max(currentIndex, 0)
                } else {
                    currentIndex = 0
                }
            }
        }
        
        checkHasChanges()
    }
    
    // MARK: - Mode & Navigation
    /// 세그먼트 모드 변경 시 호출
    func onModeChanged() {
        if mode == .batch {
            mode = .single
        } else {
            mode = .batch
        }
        updateSelectedTags()
    }
    
    // Carousel 등에서 index 변경 시 호출 (안전한 인덱스 변경)
    func onAssetChanged(to index: Int) {
        // 인덱스 유효성 검사
        guard index >= 0 && index < itemVMs.count else {
            debugPrint("⚠️ onAssetChanged: 잘못된 인덱스 \(index) (총 \(itemVMs.count)개)")
            return
        }
        
        currentIndex = index
        updateSelectedTags()
        debugPrint("🔄 currentIndex 변경: \(index)")
    }
    
    // MARK: - User Actions
    func addTagButtonTapped() {
        withAnimation {
            self.isShowingAddTagSheet = true
        }
    }
    
    // 태그 선택/해제 (안전한 배열 접근)
    func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            switch mode {
            case .batch:
                batchSelectedTags.remove(tag)
                itemVMs.forEach { $0.removeTag(tag) }
            case .single:
                // 안전한 인덱스 접근
                if currentIndex >= 0 && currentIndex < itemVMs.count {
                    itemVMs[currentIndex].removeTag(tag)
                } else {
                    debugPrint("⚠️ toggleTag(remove): 잘못된 currentIndex \(currentIndex)")
                }
            }
            selectedTags.remove(tag)
        } else if selectedTags.count < 4 {
            switch mode {
            case .batch:
                itemVMs.forEach { $0.addTag(tag) }
                batchSelectedTags.insert(tag)
            case .single:
                // 안전한 인덱스 접근
                if currentIndex >= 0 && currentIndex < itemVMs.count {
                    itemVMs[currentIndex].addTag(tag)
                } else {
                    debugPrint("⚠️ toggleTag(add): 잘못된 currentIndex \(currentIndex)")
                }
            }
            selectedTags.insert(tag)
        } else {
            // 5개째 태그를 선택하려고 할 때 토스트 표시
            canSelectTag = true
            
            // 토스트를 표시한 후 자동으로 리셋 (3.5초 후)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                self.canSelectTag = false
            }
        }
        checkHasChanges()
        updateSelectedTags()
    }
    
    // 새 태그 추가
    func addNewTag(name: String) {
        guard !tags.contains(name) else { return }
        
        // 4개 제한 확인
        if selectedTags.count >= 4 {
            // 5개째 태그를 추가하려고 할 때 토스트 표시
            canSelectTag = true
            
            // 토스트를 표시한 후 자동으로 리셋 (3.5초 후)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                self.canSelectTag = false
            }
            return
        }
        
        tags.append(name)
        
        // mode에 따라 다르게 처리
        switch mode {
        case .batch:
            // 배치 모드: 모든 아이템에 태그 추가
            itemVMs.forEach { $0.addTag(name) }
            batchSelectedTags.insert(name)
        case .single:
            // 단일 모드: 현재 아이템에만 태그 추가 (안전한 접근)
            if currentIndex >= 0 && currentIndex < itemVMs.count {
                itemVMs[currentIndex].addTag(name)
            } else {
                debugPrint("⚠️ addNewTag: 잘못된 currentIndex \(currentIndex)")
            }
        }
        
        selectedTags.insert(name)
        updateSelectedTags()
        checkHasChanges()
        
        // UserDefaults에 태그 목록 저장 (영구 저장)
        saveTags()
        
        debugPrint("✅ 새 태그 추가: \(name), 모드: \(mode)")
    }
    
    /// Favorite 상태 토글 (UI 업데이트 보장)
    func toggleFavorite(at index: Int) {
        // 완전한 인덱스 검증 (크래시 방지)
        guard index >= 0 && index < itemVMs.count else {
            debugPrint("⚠️ toggleFavorite: 잘못된 인덱스 \(index) (총 \(itemVMs.count)개)")
            return
        }
        
        let itemVM = itemVMs[index]
        itemVM.isFavorite.toggle()
        
        // UI 업데이트 강제 트리거
        updateTrigger.toggle()
        checkHasChanges()
    }
} 
