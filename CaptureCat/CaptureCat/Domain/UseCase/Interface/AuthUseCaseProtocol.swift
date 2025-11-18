//
//  AutoFlowUseCaseProtocol.swift
//  CaptureCat
//
//  Created by minsong kim on 11/17/25.
//

import Foundation

enum SocialProvider {
    case kakao
    case apple
}

enum AuthFlowResult {
    case success
    case needSignInPopup
    case failure
}

protocol AuthUseCaseProtocol {
    func autoLogin() async -> AuthFlowResult
    func login(with provider: SocialProvider) async -> AuthFlowResult
    func logout()
    func withdraw(reason: String) async -> Result<ResponseDTO, Error>
    func recentLoginTypes() -> Set<LogIn>
}
