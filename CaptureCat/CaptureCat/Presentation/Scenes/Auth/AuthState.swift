//
//  AuthState.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import Foundation

// 계정 상태 명시
enum AuthenticationState {
    case initial
    case signIn
    case guest
    case start
    case syncing        // 동기화 진행 중
    case syncCompleted  // 동기화 완료
}
