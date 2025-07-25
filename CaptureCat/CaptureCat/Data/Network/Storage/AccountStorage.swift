//
//  AccountStorage.swift
//  CaptureCat
//
//  Created by minsong kim on 7/16/25.
//

import Foundation

final class AccountStorage {
    static var shared = AccountStorage()
    
    var isGuest: Bool? {
        return accessToken?.isEmpty ?? true
    }
    
    var accessToken: String? {
        get {
            guard let token = KeyChainModule.read(key: .accessToken), !token.isEmpty else {
                return nil
            }
            
            debugPrint("🔮 get accessToken")
            return token
        }
        
        set {
            if let existingToken = KeyChainModule.read(key: .accessToken), !existingToken.isEmpty {
                KeyChainModule.delete(key: .accessToken)
            }
            
            if let value = newValue {
                KeyChainModule.create(key: .accessToken, data: value)
                debugPrint("🔮 save accessToken")
            }
        }
    }
    
    var refreshToken: String? {
        get {
            guard let token = KeyChainModule.read(key: .refreshToken), !token.isEmpty else {
                return nil
            }
            
            debugPrint("🔮 get refreshToken")
            return token
        }
        
        set {
            if let existingToken = KeyChainModule.read(key: .refreshToken), !existingToken.isEmpty {
                KeyChainModule.delete(key: .refreshToken)
            }
            
            if let value = newValue {
                KeyChainModule.create(key: .refreshToken, data: value)
                debugPrint("🔮 save refreshToken \(value)")
            }
            
            /*
             else {
                 KeyChain.delete(key: StorageKey.refreshToken)
                 debugPrint("🔮 delete refreshToken")
             }
             */
        }
    }
    
    var kakaoToken: String? {
        get {
            guard let token = KeyChainModule.read(key: .kakaoToken), !token.isEmpty else {
                return nil
            }
            return token
        }
        
        set {
            if let existingToken = KeyChainModule.read(key: .kakaoToken), !existingToken.isEmpty {
                KeyChainModule.delete(key: .kakaoToken)
            }
            
            if let value = newValue {
                KeyChainModule.create(key: .kakaoToken, data: value)
                debugPrint("🔮 save kakaoToken")
            }
        }
    }
    
    var appleToken: String? {
        get {
            guard let token = KeyChainModule.read(key: .appleToken), !token.isEmpty else {
                return nil
            }
            
            debugPrint("🔮 get appleToken")
            return token
        }
        
        set {
            if let existingToken = KeyChainModule.read(key: .appleToken), !existingToken.isEmpty {
                KeyChainModule.delete(key: .appleToken)
            }
            
            if let value = newValue {
                KeyChainModule.create(key: .appleToken, data: value)
                debugPrint("🔮 save appleToken")
            }
        }
    }
    
    func reset() {
        accessToken = nil
        refreshToken = nil
        clearAllTokens()
    }
    
    /// 안전한 리셋 (연쇄 삭제 방지)
    func safeReset() {
        debugPrint("🔮 안전한 AccountStorage 리셋 시작")
        
        // 프로퍼티 리셋 (내부적으로 키체인 삭제 시도하지만 에러 무시됨)
        accessToken = nil
        refreshToken = nil
        
        // 추가 정리 작업
        safelyClearAllTokens()
        
        debugPrint("🔮 안전한 AccountStorage 리셋 완료")
    }
    
    func clearAllTokens() {
        KeyChainModule.delete(key: .accessToken)
        KeyChainModule.delete(key: .refreshToken)
        
        debugPrint("🔮 All tokens cleared from Keychain")
    }
    
    /// 안전한 토큰 정리 (에러 무시)
    private func safelyClearAllTokens() {
        debugPrint("🔮 안전한 토큰 정리 시작")
        
        // 각 토큰을 개별적으로 삭제하고 에러 무시
        do {
            debugPrint("🔮 AccessToken 키체인 삭제 시도")
            KeyChainModule.delete(key: .accessToken)
        }
        
        do {
            debugPrint("🔮 RefreshToken 키체인 삭제 시도")
            KeyChainModule.delete(key: .refreshToken)
        }
        
        do {
            debugPrint("🔮 KakaoToken 키체인 삭제 시도")
            KeyChainModule.delete(key: .kakaoToken)
        }
        
        do {
            debugPrint("🔮 AppleToken 키체인 삭제 시도")
            KeyChainModule.delete(key: .appleToken)
        }
        
        debugPrint("🔮 안전한 토큰 정리 완료")
    }
}
