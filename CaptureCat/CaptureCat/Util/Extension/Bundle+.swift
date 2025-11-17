//
//  Bundle+.swift
//  CaptureCat
//
//  Created by minsong kim on 7/17/25.
//

import Foundation

extension Bundle {
    var kakaoKey: String? {
        object(forInfoDictionaryKey: "KAKAO_API_KEY") as? String
    }
    
    var mixpanelToken: String? {
        object(forInfoDictionaryKey: "MIXPANEL_TOKEN") as? String
    }
    
    var baseURL: URL? {
        URL(string: object(forInfoDictionaryKey: "BASE_URL") as? String ?? "")
    }
}

extension Bundle {
    /// CFBundleShortVersionString
    var appVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    /// CFBundleVersion
    var appBuild: String {
        infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
}
