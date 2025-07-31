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
    
    func trackImageSave(entry: SaveImageEntry, tagging: TaggingMode, tagCount: Int, screenshotCount: Int) {
        mixpanel.track(event: "click_save_image", properties: [
            "entry_point" : entry.value,
            "tagging_mode" : tagging.value,
            "tag_count_total": tagCount,
            "screenshot_count": screenshotCount
        ])
    }
    
    func trackLogIn(method: LogIn, before: UserType) {
        mixpanel.track(event: "complete_login", properties: [
            "login_method": method.value,
            "user_type_before": before.value
        ])
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

enum TaggingMode {
    case batch
    case single
    
    var value: String {
        switch self {
        case .batch:
            "batch"
        case .single:
            "single"
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
