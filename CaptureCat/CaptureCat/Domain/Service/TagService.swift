//
//  TagService.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

final class TagService {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func createUserTag(tag: String) async -> Result<UserTagDTO, Error> {
        let builder = CreateUserTagBuilder(tagName: tag)
        
        do {
            let result = try await networkManager.fetchData(builder)
            return Result<UserTagDTO, Error>.success(result)
        } catch {
            return .failure(error)
        }
    }
    
    func fetchUserTagList() async -> Result<TagDTO, Error> {
        let builder = UserTagListBuilder()
        
        do {
            let result = try await networkManager.fetchData(builder)
            return Result<TagDTO, Error>.success(result)
        } catch {
            return .failure(error)
        }
    }
    
    func updateUserTag(tag: Tag) async -> Result<UserTagDTO, Error> {
        let builder = UpdateUserTagBuilder(newTag: tag.name, id: tag.id)
        
        do {
            let result = try await networkManager.fetchData(builder)
            return Result<UserTagDTO, Error>.success(result)
        } catch {
            return .failure(error)
        }
    }
    
    func deleteUserTag(id: Int) async -> Result<ResponseDTO, Error> {
        let builder = DeleteUserTagBuilder(tagId: String(id))
        
        do {
            let result = try await networkManager.fetchData(builder)
            return Result<ResponseDTO, Error>.success(result)
        } catch {
            return .failure(error)
        }
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
