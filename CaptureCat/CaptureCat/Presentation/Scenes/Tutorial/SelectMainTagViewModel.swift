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
    enum Topic: String, CaseIterable, Identifiable {
        case shopping, job, reference, fashion, study, quotes, travel, selfImprovement, restaurant, music, recipe, fitness

        // 1) 로컬라이징 키 (String) — Localizable.strings의 키
        var i18nKey: String {
            switch self {
            case .shopping:         return "topic.shopping"
            case .job:              return "topic.job"
            case .reference:        return "topic.reference"
            case .fashion:          return "topic.fashion"
            case .study:            return "topic.study"
            case .quotes:           return "topic.quotes"
            case .travel:           return "topic.travel"
            case .selfImprovement:  return "topic.selfImprovement"
            case .restaurant:       return "topic.restaurant"
            case .music:            return "topic.music"
            case .recipe:           return "topic.recipe"
            case .fitness:          return "topic.fitness"
            }
        }

        // 2) SwiftUI용 표시 키
        var localizedKey: LocalizedStringKey { LocalizedStringKey(i18nKey) }

        // 3) 실제 번역된 문자열 (저장용)
        var localizedText: String { NSLocalizedString(i18nKey, comment: "") }

        // Identifiable
        var id: String { i18nKey }
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
//    func saveTopicLocal() {
//        UserDefaults.standard.set(
//            selected.map { NSLocalizedString( $0.localKey, comment: "") },
//            forKey: LocalUserKeys.selectedTopics.rawValue
//        )
//    }
    func saveTopicLocal() {
        let texts = selected.map { $0.localizedText } // 저장 시점 언어로 고정
        UserDefaults.standard.set(texts, forKey: LocalUserKeys.selectedTopics.rawValue)
    }
}
