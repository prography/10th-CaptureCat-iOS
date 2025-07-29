//
//  TagViewModel+DeleteManagement.swift
//  CaptureCat
//
//  Created by AI Assistant on 1/15/25.
//

import SwiftUI

// MARK: - Delete Management
extension TagViewModel {
    /// 삭제 작업 큐 시스템 프로퍼티들
    var deletionQueue: DispatchQueue {
        DispatchQueue(label: "com.capturecat.deletion", qos: .userInitiated)
    }
    
    /// 특정 인덱스의 아이템 안전하게 삭제 (큐 시스템 사용)
    func deleteItem(at index: Int) {
        // 인덱스 유효성 검사
        guard index >= 0 && index < itemVMs.count else {
            debugPrint("❌ 잘못된 인덱스로 삭제 시도: \(index) (총 \(itemVMs.count)개)")
            return
        }
        
        // 삭제 요청을 큐에 추가 (디바운싱 효과)
        addDeletionToQueue(index: index)
    }
    
    /// 삭제 요청을 큐에 추가하고 처리 시작
    private func addDeletionToQueue(index: Int) {
        deletionQueue.async { [weak self] in
            guard let self = self else { return }
            
            // 중복 요청 필터링 (같은 인덱스가 이미 큐에 있으면 무시)
            if !self.pendingDeletions.contains(index) {
                self.pendingDeletions.append(index)
                debugPrint("📥 삭제 큐에 추가: 인덱스 \(index)")
            }
            
            // 삭제 처리 시작
            self.processDeletionQueue()
        }
    }
    
    /// 삭제 큐 순차 처리
    private func processDeletionQueue() {
        // 이미 처리 중이면 스킵
        guard !isProcessingDeletion, !pendingDeletions.isEmpty else { return }
        
        isProcessingDeletion = true
        
        Task { @MainActor in
            // UI 상태 업데이트
            isDeletingItem = true
            deletionProgress = "삭제 중... (\(pendingDeletions.count)개 대기)"
            
            await performQueuedDeletions()
            
            // 완료 후 상태 정리
            isDeletingItem = false
            deletionProgress = ""
            isProcessingDeletion = false
        }
    }
    
    /// 큐에 있는 삭제 작업들을 순차 실행
    @MainActor
    private func performQueuedDeletions() async {
        while !pendingDeletions.isEmpty {
            // 큐에서 가장 앞의 인덱스 가져오기
            let targetIndex = pendingDeletions.removeFirst()
            
            // 현재 배열 상태에서 유효한 인덱스인지 재확인
            guard targetIndex >= 0 && targetIndex < itemVMs.count else {
                debugPrint("⚠️ 큐 처리 중 잘못된 인덱스: \(targetIndex)")
                continue
            }
            
            let itemVM = itemVMs[targetIndex]
            let itemId = itemVM.id
            let fileName = itemVM.fileName
            
            debugPrint("🗑️ 큐에서 삭제 처리: [\(targetIndex)] \(fileName)")
            
            do {
                // 2단계: 메모리에서 제거 (배치 처리)
                await safelyRemoveItemWithBatching(at: targetIndex)
                
                // 3단계: 약간의 지연으로 안정성 확보
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1초
                
            } catch {
                debugPrint("❌ 큐 삭제 실패: \(error.localizedDescription)")
            }
            
            // 진행률 업데이트
            deletionProgress = pendingDeletions.isEmpty ? "" : "삭제 중... (\(pendingDeletions.count)개 대기)"
        }
        
        debugPrint("✅ 모든 삭제 작업 완료")
    }
    
    /// UI에서 아이템을 배치 처리로 안전하게 제거 (메인 스레드 전용)
    @MainActor
    private func safelyRemoveItemWithBatching(at index: Int) async {
        // 재차 인덱스 유효성 검사 (비동기 처리 중 배열 변경 가능성)
        guard index >= 0 && index < itemVMs.count else {
            debugPrint("❌ UI 제거 시 잘못된 인덱스: \(index) (총 \(itemVMs.count)개)")
            return
        }
        
        // 1단계: 데이터 변경 (애니메이션 없이)
        let removedItem = itemVMs.remove(at: index)
        debugPrint("🗂️ 메모리에서 제거: \(removedItem.fileName)")
        
        // 2단계: 인덱스 조정
        adjustCurrentIndexSafely()
        
        // 3단계: 모든 아이템이 삭제된 경우 처리
        if itemVMs.isEmpty {
            debugPrint("⚠️ 모든 아이템이 삭제되었습니다. 이전 페이지로 이동합니다.")
            router?.pop()
            return
        }
        
        // 4단계: 상태 업데이트 (배치 처리)
        await performBatchedUIUpdate()
        
        debugPrint("✅ 배치 UI 업데이트 완료: 남은 아이템 \(itemVMs.count)개, 현재 인덱스: \(currentIndex)")
    }
    
    /// 배치 UI 업데이트 (모든 상태 변경을 한 번에 처리)
    @MainActor
    private func performBatchedUIUpdate() async {
        // 모든 UI 관련 업데이트를 defer로 묶어서 처리
        defer {
            updateTrigger.toggle()  // 마지막에 UI 강제 업데이트
            shouldSyncCarousel.toggle()  // 캐러셀 동기화 트리거
        }
        
        // 태그 상태 갱신
        updateSelectedTags()
        
        // 약간의 지연으로 SwiftUI 렌더링 안정화
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05초
    }
    
    /// UI에서 아이템을 안전하게 제거 (기존 메서드 유지 - 호환성)
    @MainActor
    private func safelyRemoveItem(at index: Int) {
        Task {
            await safelyRemoveItemWithBatching(at: index)
        }
    }
    
    /// 현재 인덱스를 안전하게 조정
    @MainActor
    private func adjustCurrentIndexSafely() {
        let itemCount = itemVMs.count
        let oldIndex = currentIndex
        
        if itemCount == 0 {
            currentIndex = 0
        } else if currentIndex >= itemCount {
            // 마지막 아이템을 삭제한 경우
            currentIndex = itemCount - 1
        } else if currentIndex < 0 {
            // 음수 인덱스 보정
            currentIndex = 0
        }
        // currentIndex가 유효한 범위인 경우는 그대로 유지
        
        debugPrint("🔧 인덱스 조정: \(oldIndex) → \(currentIndex) (총 \(itemCount)개)")
    }
} 
