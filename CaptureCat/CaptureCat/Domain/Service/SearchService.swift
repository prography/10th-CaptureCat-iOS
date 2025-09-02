//
//  SearchService.swift
//  CaptureCat
//
//  Created by minsong kim on 8/31/25.
//

import Foundation

final class SearchService {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }

    func searchTag(by tag: String) async -> Result<SearchDTO, Error> {
        let builder = SearchAutoBuilder(keyword: tag)
        
        do {
            let response = try await networkManager.fetchData(builder)
            return Result<SearchDTO, Error>.success(response)
        } catch (let error) {
            debugPrint("🔥 Error:\(error)")
            return .failure(error)
        }
    }
}
