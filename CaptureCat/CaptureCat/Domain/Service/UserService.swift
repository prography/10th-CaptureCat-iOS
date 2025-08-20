//
//  UserService.swift
//  CaptureCat
//
//  Created by minsong kim on 8/16/25.
//

import Foundation

final class UserService {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func userInfo() async -> Result<LogInResponseDTO, Error> {
        let builder = UserInfoBuilder()
        
        do {
            let response = try await networkManager.fetchData(builder)
            return Result<LogInResponseDTO, Error>.success(response)
        } catch (let error) {
            debugPrint("🔥 Error:\(error)")
            return .failure(error)
        }
    }
}
