//
//  AppVersion.swift
//  CaptureCat
//
//  Created by minsong kim on 8/14/25.
//

import Foundation

struct AppVersion: Comparable {
    let parts: [Int]

    init(_ string: String) {
        self.parts = string
            .split(separator: ".")
            .map { Int($0) ?? 0 }
    }

    static func < (local: AppVersion, store: AppVersion) -> Bool {
        let maxCount = max(local.parts.count, store.parts.count)
        for i in 0..<maxCount {
            let l = i < local.parts.count ? local.parts[i] : 0
            let r = i < store.parts.count ? store.parts[i] : 0
            if l != r { return l < r }
        }
        return false
    }
}

extension Bundle {
    var shortVersion: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
    }
}
