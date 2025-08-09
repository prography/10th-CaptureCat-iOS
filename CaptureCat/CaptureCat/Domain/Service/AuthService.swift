//
//  AuthService.swift
//  CaptureCat
//
//  Created by minsong kim on 7/16/25.
//

import Foundation

final class AuthService {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func login(social: String, idToken: String?, authToken: String?, nickname: String?) async -> Result<LogInResponseDTO, NetworkError> {
        let builder = AuthBuilder(social: social, idToken: idToken, authToken: authToken, nickname: nickname)
        
        do {
            let response = try await networkManager.fetchLoginData(builder)
            return Result<LogInResponseDTO, NetworkError>.success(response)
        } catch {
            debugPrint("🔥 Error:\(error)")
            return .failure(NetworkError.unauthorized)
        }
    }
    
    func withdraw() async -> Result<ResponseDTO, Error> {
        let builder = WithdrawBuilder()
        
        do {
            let response = try await networkManager.fetchData(builder)
            return Result<ResponseDTO, Error>.success(response)
        } catch {
            debugPrint("🔥 Withdraw Error:\(error)")
            return .failure(error)
        }
    }
}
