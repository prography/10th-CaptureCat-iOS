//
//  UpdateViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 8/14/25.
//

import Combine
import SwiftUI

enum UpdateState: Equatable {
    case none
    case optional(minVersion: String)
    case forced(minVersion: String)
}

@MainActor
final class UpdateViewModel: ObservableObject {
    @Published var showOptional = false   // 선택 업데이트 팝업 표시
    @Published var showForced = false     // 강제 업데이트 팝업 표시
    @Published var requiredVersion = ""
    
    private let rcService = RemoteConfigService()

    func checkNow() async {
        do {
            let cfg = try await rcService.fetchUpdateConfig()
            let current = AppVersion(Bundle.main.shortVersion)
            let min = AppVersion(cfg.minVersion)
            
            showOptional = false
            showForced = false
            
            if current < min {
                requiredVersion = cfg.minVersion
                if cfg.forceUpdate {
                    showForced = true
                } else {
                    showOptional = true
                }
            }
        } catch {
            showForced = false
            showForced = false
        }
    }
    
    func dismissAll() {
        showOptional = false
        showForced = false
    }
}
