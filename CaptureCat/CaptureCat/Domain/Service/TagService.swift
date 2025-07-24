//
//  TagService.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

final class TagService {
    static let shared: TagService = TagService()
    private let networkManager: NetworkManager
    
    private init() {
        self.networkManager = NetworkManager(baseURL: BaseURLType.production.url!)
    }
    
    func fetchPopularTagList() async -> Result<TagDTO, Error> {
        let builder = PopularTagBuilder()
        
        do {
            let result = try await networkManager.fetchData(builder)
            return Result<TagDTO, Error>.success(result)
        } catch (let error) {
            return .failure(error)
        }
    }
    
    func fetchRelatedTagList(page: Int, size: Int, tags: [String]) async -> Result<TagDTO, Error> {
        let builder = RelatedTagListBuilder(page: page, size: size, tags: tags)
        
        do {
            let result = try await networkManager.fetchData(builder)
            return Result<TagDTO, Error>.success(result)
        } catch (let error) {
            return .failure(error)
        }
    }
}
