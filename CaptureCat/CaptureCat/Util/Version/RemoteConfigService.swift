//
//  RemoteConfigService.swift
//  CaptureCat
//
//  Created by minsong kim on 8/14/25.
//

import FirebaseRemoteConfig

struct UpdateConfig {
    let minVersion: String
    let forceUpdate: Bool
}

final class RemoteConfigService {
    private let rc = RemoteConfig.remoteConfig()

    init() {
        // 기본값(네트워크 실패 시 안전하게 동작)
        rc.setDefaults([
            "iOS_min_supported_version": "0.0.0" as NSObject,
            "iOS_force_update": false as NSObject
        ])
        #if DEBUG
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // 디버그: 매번 패치
        rc.configSettings = settings
        #endif
    }

    func fetchUpdateConfig() async throws -> UpdateConfig {
        try await withCheckedThrowingContinuation { cont in
            rc.fetchAndActivate { _, error in
                if let error { cont.resume(throwing: error); return }
                let minVer = self.rc.configValue(forKey: "iOS_min_supported_version").stringValue ?? "0.0.0"
                let force = self.rc.configValue(forKey: "iOS_force_update").boolValue
                cont.resume(returning: UpdateConfig(minVersion: minVer, forceUpdate: force))
            }
        }
    }
}
