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
