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
    case deleteOriginalsAfterSave = "deleteOriginalsAfterSave"
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
    
    private var repository: ScreenshotRepository
    
    // MARK: - Init
    init(repository: ScreenshotRepository) {
        self.repository = repository
    }
    
    // 최대 선택 개수
    let maxSelection = 5
    
    // 현재 선택 개수 / 최대치 표시 문자열
    var selectionText: LocalizedStringKey {
        "선택 완료 \(selected.count)/\(maxSelection)"
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
        UserDefaults.standard.selectedTopics = texts
        
        // 로그인 상태인 경우 서버에 userTag로 등록
        if !(AccountStorage.shared.isGuest ?? true) {
            registerSelectedTopicsToServer()
        }
    }
    
    /// 선택된 토픽들을 서버에 userTag로 등록
    private func registerSelectedTopicsToServer() {
        Task {
            for topic in selected {
                do {
                    let result = try await repository.registerUserTag(name: topic.localizedText)
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
    }
}
