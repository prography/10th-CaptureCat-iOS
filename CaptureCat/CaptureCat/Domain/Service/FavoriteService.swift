//
//  FavoriteService.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

final class FavoriteService {
    static let shared: FavoriteService = FavoriteService()
    private let networkManager: NetworkManager
    
    private init() {
        self.networkManager = NetworkManager(baseURL: BaseURLType.production.url!)
    }
    
    func uploadFavorite(id: String) async -> Result<ResponseDTO, Error> {
        let builder = UploadFavoriteBuilder(imageId: id)
        
        do {
            let result = try await networkManager.fetchData(builder)
            return Result<ResponseDTO, Error>.success(result)
        } catch {
            return .failure(error)
        }
    }
    
    func deleteFavorite(id: String) async -> Result<ResponseDTO, Error> {
        let builder = DeleteFavoriteBuilder(imageId: id)
        
        do {
            let result = try await networkManager.fetchData(builder)
            return Result<ResponseDTO, Error>.success(result)
        } catch {
            return .failure(error)
        }
    }
    
    func checkFavoriteImageList(page: Int, size: Int) async -> Result<FavoriteImageDTO, Error> {
        let builder = FavoriteImageBuilder(page: page, size: size)
        
        do {
            let response = try await networkManager.fetchData(builder)
            debugPrint("✅ Success: \(page) 이미지 목록 불러오기 성공!")
            return Result<FavoriteImageDTO, Error>.success(response)
        } catch {
            return .failure(error)
        }
    }
}
