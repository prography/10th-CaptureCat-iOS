//
//  SelectMainTagViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import Combine
import SwiftUI

enum LocalUserKeys: String {
    case selectedTopics = "selectedTopics"
}

final class SelectMainTagViewModel: ObservableObject {
    // 전체 토픽 목록
    enum Topic: String, CaseIterable, Identifiable {
        case shopping
        case job
        case reference
        case fashion
        case study
        case quotes
        case travel
        case selfImprovement
        case restaurant
        case music
        case recipe
        case fitness
        
        var id: String {
            switch self {
            case .shopping:
                "쇼핑"
            case .job:
                "직무 관련"
            case .reference:
                "레퍼런스"
            case .fashion:
                "코디"
            case .study:
                "공부"
            case .quotes:
                "글귀"
            case .travel:
                "여행"
            case .selfImprovement:
                "자기계발"
            case .restaurant:
                "맛집"
            case .music:
                "노래"
            case .recipe:
                "레시피"
            case .fitness:
                "운동"
            }
        }
        
        var localKey: LocalizedStringKey {
            switch self {
            case .shopping:
                "쇼핑"
            case .job:
                "직무 관련"
            case .reference:
                "레퍼런스"
            case .fashion:
                "코디"
            case .study:
                "공부"
            case .quotes:
                "글귀"
            case .travel:
                "여행"
            case .selfImprovement:
                "자기계발"
            case .restaurant:
                "맛집"
            case .music:
                "노래"
            case .recipe:
                "레시피"
            case .fitness:
                "운동"
            }
        }
    }
    
    // 선택된 토픽 집합
    @Published private(set) var selected: Set<Topic> = []
    
    private var networkManager: NetworkManager
    
    // MARK: - Init
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    // 최대 선택 개수
    let maxSelection = 5
    
    // 현재 선택 개수 / 최대치 표시 문자열
    var selectionText: LocalizedStringKey {
        "선택 완료 \(selected.count)/\(maxSelection)"
    }
    
    // 토픽을 4개씩 묶어주는 유틸
    var rows: [[Topic]] {
        Topic.allCases.chunked(into: 4)
    }
    
    // 토글 액션
    func toggle(_ topic: Topic) {
        if selected.contains(topic) {
            selected.remove(topic)
        } else if selected.count < maxSelection {
            selected.insert(topic)
        }
    }
    
    // 태그 저장 (로컬에서)
    func saveTopicLocal() {
        UserDefaults.standard.set(
            selected.map { $0.id },
            forKey: LocalUserKeys.selectedTopics.rawValue
        )
    }
}
