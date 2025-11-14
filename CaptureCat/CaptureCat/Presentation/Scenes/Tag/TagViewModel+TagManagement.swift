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
        // single 모드에서는 이미 selectedTags를 직접 업데이트했으므로 updateSelectedTags() 호출 불필요
        // batch 모드에서는 batchSelectedTags와 selectedTags를 동기화해야 함
        if mode == .batch {
            updateSelectedTags()
        }
    }
    
    // 새 태그 추가 또는 기존 태그 선택
    func addNewTag(name: String) {
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
        
        // 새로운 태그인 경우에만 tags 배열에 추가
        if !tags.contains(name) {
            tags.append(name)
            // UserDefaults에 태그 목록 저장 (새 태그만)
            saveTags()
            // 서버에 userTag로 등록 (게스트가 아닌 경우, 새 태그만)
            registerTagToServer(name)
        }
        
        // 기존 태그든 새 태그든 현재 이미지에 적용
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
        checkHasChanges()
        
        debugPrint("✅ 태그 선택/추가: \(name), 모드: \(mode)")
    }
    
    /// 서버에 userTag로 등록
    private func registerTagToServer(_ tagName: String) {
        // 게스트 모드인지 확인
        guard !(AccountStorage.shared.isGuest ?? true) else {
            debugPrint("🔄 게스트 모드: 서버 태그 등록 건너뜀")
            return
        }
        
        Task {
            do {
                let result = try await repository.registerUserTag(name: tagName)
                switch result {
                case .success(let userTag):
                    debugPrint("✅ 서버 태그 등록 성공: \(userTag.data.name)")
                case .failure(let error):
                    debugPrint("❌ 서버 태그 등록 실패: \(error)")
                    // "이미 등록된 태그" 에러든 다른 에러든 상관없이 로컬 태그는 유지
                    // 사용자는 이미 태그를 선택했으므로 서버 상태와 무관하게 로컬에서 사용 가능
                }
            } catch {
                debugPrint("❌ 서버 태그 등록 중 오류: \(error.localizedDescription)")
                // 네트워크 오류 등 모든 예외 상황에서도 로컬 태그는 유지
            }
        }
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
