//
//  SelectMainTagViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import Combine
import SwiftUI

// 화면에 표시할 토픽 모델
struct Topic: Identifiable, Hashable {
    let id = UUID()
    let title: String
}

final class SelectMainTagViewModel: ObservableObject {
    // 전체 토픽 목록
    let topics: [Topic] = [
        "쇼핑", "직무 관련", "레퍼런스", "코디",
        "공부", "글귀", "여행", "자기계발",
        "맛집", "new", "new", "new"
    ].map(Topic.init)
    
    // 선택된 토픽 집합
    @Published private(set) var selected: Set<Topic> = []
    
    // 최대 선택 개수
    let maxSelection = 5
    
    // 토글 액션
    func toggle(_ topic: Topic) {
        if selected.contains(topic) {
            selected.remove(topic)
        } else if selected.count < maxSelection {
            selected.insert(topic)
        }
    }
    
    // 현재 선택 개수 / 최대치 표시 문자열
    var selectionText: String {
        "선택 완료 \(selected.count)/\(maxSelection)"
    }
    
    // 토픽을 4개씩 묶어주는 유틸
    var rows: [[Topic]] {
        topics.chunked(into: 4)
    }
}
