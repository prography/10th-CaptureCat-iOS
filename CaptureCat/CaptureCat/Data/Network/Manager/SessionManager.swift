//
//  SessionManager.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import Foundation

protocol SessionManaging {
    func markRecentLogin(_ provider: SocialProvider)
    func clearSession()
    func clearSessionForWithdraw()
    func recentLoginTypes() -> Set<LogIn>
}

final class SessionManager: SessionManaging {
    func markRecentLogin(_ provider: SocialProvider) {
        switch provider {
        case .apple:
            KeyChainModule.create(key: .isRecentApple, data: "true")
            KeyChainModule.delete(key: .isRecentKakao)
        case .kakao:
            KeyChainModule.create(key: .isRecentKakao, data: "true")
            KeyChainModule.delete(key: .isRecentApple)
        }
    }
    
    func clearSession() {
        KeyChainModule.delete(key: .accessToken)
        KeyChainModule.delete(key: .refreshToken)
        KeyChainModule.delete(key: .appleToken)
        KeyChainModule.delete(key: .kakaoToken)
        AccountStorage.shared.safeReset()
    }
    
    func clearSessionForWithdraw() {
        KeyChainModule.delete(key: .didStarted)
        KeyChainModule.delete(key: .isRecentApple)
        KeyChainModule.delete(key: .isRecentKakao)
        clearUserDefaults()
        clearSession()
    }
    
    func recentLoginTypes() -> Set<LogIn> {
        var types: Set<LogIn> = []
        if KeyChainModule.read(key: .isRecentApple) == "true" { types.insert(.apple) }
        if KeyChainModule.read(key: .isRecentKakao) == "true" { types.insert(.kakao) }
        return types
    }
    
    private func clearUserDefaults() {
        UserDefaults.standard.removeObject(forKey: LocalUserKeys.selectedTopics.rawValue)
        UserDefaults.standard.removeObject(forKey: LocalUserKeys.deleteOriginalsAfterSave.rawValue)
        UserDefaults.standard.removeObject(forKey: LocalUserKeys.taggedImageIds.rawValue)
        UserDefaults.standard.removeObject(forKey: LocalUserKeys.didImageDeleteBottomSheetPresented.rawValue)
        UserDefaults.standard.synchronize()
    }
}

