//
//  TutorialService.swift
//  CaptureCat
//
//  Created by minsong kim on 7/23/25.
//

import Foundation

final class TutorialService {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func turorialComplete() async -> Result<ResponseDTO, Error> {
        let builder = TutorialBuilder()
        
        do {
            let response = try await networkManager.fetchData(builder)
            return Result<ResponseDTO, Error>.success(response)
        } catch (let error) {
            debugPrint("🔥 Error:\(error)")
            return .failure(error)
        }
    }
}
