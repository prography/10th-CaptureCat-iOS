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
    
    func clearAllTokens() {
        KeyChainModule.delete(key: .accessToken)
        KeyChainModule.delete(key: .refreshToken)
        
        debugPrint("🔮 All tokens cleared from Keychain")
    }
}
