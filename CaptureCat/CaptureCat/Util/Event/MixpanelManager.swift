//
//  MixpanelManager.swift
//  CaptureCat
//
//  Created by minsong kim on 7/31/25.
//

import Mixpanel
import Foundation

struct MixpanelManager {
    static let shared = MixpanelManager()
    
    private init() {}
    
    private var mixpanel = Mixpanel.mainInstance()
    
    func trackStartView() {
        mixpanel.track(event: "view_start")
    }
    
    func trackInterestTag(_ tags: [String]) {
        mixpanel.track(event: "click_register_frequent_tag", properties: ["selected_tags" : tags])
    }
    
    func trackStartStorage() {
        mixpanel.track(event: "view_start_inbox")
    }
    
    func trackImageSave(entry: SaveImageEntry, tagging: Mode, tagCount: Int, screenshotCount: Int) {
        mixpanel.track(event: "click_save_image", properties: [
            "entry_point" : entry.value,
            "tagging_mode" : tagging.value,
            "tag_count_total": tagCount,
            "screenshot_count": screenshotCount
        ])
    }
    
    func trackDetailView(id: String) {
        mixpanel.track(event: "view_image_detail", properties: [
            "image_id": "img_\(id)"
        ])
    }
    
    func trackLogIn(method: LogIn, before: UserType) {
        mixpanel.track(event: "complete_login", properties: [
            "login_method": method.value,
            "user_type_before": before.value
        ])
    }
    
    //이미 계정이 있고, 로그인 시
    func identifyUser(userId: String) {
        // Simplified ID Merge인 경우 identify만으로 익명 행동이 붙는다.
        mixpanel.identify(distinctId: userId)
        
        // people profile 설정 (한 번만 세팅하고 싶으면 setOnce)
        mixpanel.people.set(properties: [
            "$user_id": userId, // 내부 고유 ID
            "last_login": Date()
        ])
    }
    
    //로그아웃
    func logout() {
        mixpanel.reset() // 익명 상태로 초기화, super properties도 지워짐
    }
    
    func withdraw() {
        mixpanel.people.deleteUser()
        mixpanel.flush()
        mixpanel.reset()
    }
    
    //회원 가입 직후
    func signIn(userId: String) {
        mixpanel.createAlias(userId, distinctId: mixpanel.distinctId)
        mixpanel.identify(distinctId: userId)
    }

}

enum SaveImageEntry {
    case start
    case inbox
    
    var value: String {
        switch self {
        case .start:
            "start_inbox"
        case .inbox:
            "inbox"
        }
    }
}

enum UserType {
    case guest
    case known
    
    var value: String {
        switch self {
        case .guest:
            "guest"
        case .known:
            "known"
        }
    }
}
