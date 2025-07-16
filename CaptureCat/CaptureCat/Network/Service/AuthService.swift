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
    
    func login(social: String, idToken: String) async -> Result<LogInResponseDTO, NetworkError> {
        let builder = AuthBuilder(social: social, idToken: idToken)
        
        do {
            let response = try await networkManager.fetchLoginData(builder)
            return Result<LogInResponseDTO, NetworkError>.success(response)
        } catch(let error) {
            debugPrint("🔥 Error:\(error)")
            return .failure(NetworkError.unauthorized)
        }
    }
}
