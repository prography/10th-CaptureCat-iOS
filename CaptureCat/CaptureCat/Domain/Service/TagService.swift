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
        } catch {
            return .failure(error)
        }
    }
    
    func fetchRelatedTagList(page: Int, size: Int, tags: [String]) async -> Result<TagDTO, Error> {
        let builder = RelatedTagListBuilder(page: page, size: size, tags: tags)
        
        do {
            let result = try await networkManager.fetchData(builder)
            return Result<TagDTO, Error>.success(result)
        } catch {
            return .failure(error)
        }
    }
    
    func updateTag(imageId: String, tags: [String]) async -> Result<TagListDTO, Error> {
        let builder = UpdateTagBuilder(imageId: imageId, tags: tags)
        
        do {
            let result = try await networkManager.fetchData(builder)
            return Result<TagListDTO, Error>.success(result)
        } catch {
            return .failure(error)
        }
    }
    
    func deleteTag(imageId: String, tagId: String) async -> Result<ResponseDTO, Error> {
        let builder = DeleteTagBuilder(imageId: imageId, tagId: tagId)
        
        do {
            let result = try await networkManager.fetchData(builder)
            return Result<ResponseDTO, Error>.success(result)
        } catch {
            return .failure(error)
        }
    }
}
