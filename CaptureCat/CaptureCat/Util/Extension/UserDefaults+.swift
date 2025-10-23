//
//  UserDefaults+Extensions.swift
//  CaptureCat
//
//  Created by minsong kim on 1/15/25.
//

import Foundation

// MARK: - UserDefaults Extensions for App Settings
extension UserDefaults {
    
    /// 이미지 저장 후 원본 삭제 설정 값 가져오기 (기본값: true)
    var deleteOriginalsAfterSave: Bool {
        get {
            // 처음 접근 시 기본값 true로 설정
            if object(forKey: LocalUserKeys.deleteOriginalsAfterSave.rawValue) == nil {
                set(true, forKey: LocalUserKeys.deleteOriginalsAfterSave.rawValue)
                synchronize()
                debugPrint("🔧 원본 이미지 삭제 설정 초기값 설정: true")
                return true
            }
            return bool(forKey: LocalUserKeys.deleteOriginalsAfterSave.rawValue)
        }
        set {
            set(newValue, forKey: LocalUserKeys.deleteOriginalsAfterSave.rawValue)
            synchronize()
            debugPrint("🔧 원본 이미지 삭제 설정 변경: \(newValue)")
        }
    }
    
    /// 선택된 토픽 목록 가져오기
    var selectedTopics: [String] {
        get {
            return stringArray(forKey: LocalUserKeys.selectedTopics.rawValue) ?? []
        }
        set {
            set(newValue, forKey: LocalUserKeys.selectedTopics.rawValue)
            synchronize()
            debugPrint("🔧 선택된 토픽 목록 변경: \(newValue)")
        }
    }
    
    /// 태그된 이미지 ID 목록 가져오기
    var taggedImageIds: Set<String> {
        get {
            let array = stringArray(forKey: LocalUserKeys.taggedImageIds.rawValue) ?? []
            return Set(array)
        }
        set {
            set(Array(newValue), forKey: LocalUserKeys.taggedImageIds.rawValue)
            synchronize()
            debugPrint("🔧 태그된 이미지 ID 목록 변경: \(newValue.count)개")
        }
    }
}
