//
//  ImageService.swift
//  CaptureCat
//
//  Created by minsong kim on 7/17/25.
//

import Foundation

final class ImageService {
    static let shared: ImageService = ImageService()
    private let networkManager: NetworkManager
    
    private init() {
        self.networkManager = NetworkManager(baseURL: BaseURLType.production.url!)
    }
    
    func uploadImages(imageDatas: [Data], imageMetas: [PhotoDTO]) async -> Result<ResponseDTO, Error> {
        let builder = UploadImageBuilder(imageDatas: imageDatas, imageMetas: imageMetas)
        
        do {
            let response = try await networkManager.fetchData(builder)
            debugPrint("✅ Success: 이미지 파일들 업로드 성공!")
            return Result<ResponseDTO, Error>.success(response)
        } catch (let error) {
            debugPrint("🔥 Error:\(error)")
            return .failure(error)
        }
    }
    
    // 🚫 서버 태그 추가 기능 임시 비활성화
    /*
    func addImage(tags: [String], id: String) async -> Result<ResponseDTO, Error> {
        let builder = AddOneImageTagBuilder(id: id, tags: tags)
        
        do {
            let response = try await networkManager.fetchData(builder)
            debugPrint("✅ Success: \(tags) 태그 추가 성공!")
            return Result<ResponseDTO, Error>.success(response)
        } catch(let error) {
            return .failure(error)
        }
    }
    */
    
    func checkImageList(page: Int, size: Int, hasTags: Bool? = nil) async -> Result<ImagListDTO, Error> {
        let builder = CheckImageListBuilder(page: page, size: size, hasTags: hasTags)
        
        do {
            let response = try await networkManager.fetchData(builder)
            debugPrint("✅ Success: \(page) 이미지 목록 불러오기 성공!")
            return Result<ImagListDTO, Error>.success(response)
        } catch (let error) {
            return .failure(error)
        }
    }
    
    func checkImageList(by tags: [String], page: Int, size: Int) async -> Result<ImagListDTO, Error> {
        let builder = CheckImageListWithTagBuilder(page: page, size: size, tagNames: tags)
        
        do {
            let response = try await networkManager.fetchData(builder)
            debugPrint("✅ Success: \(page) 이미지 목록 불러오기 성공!")
            return Result<ImagListDTO, Error>.success(response)
        } catch (let error) {
            return .failure(error)
        }
    }
    
    func deleteImage(id: String) async -> Result<ResponseDTO, Error> {
        let builder = DeleteImageBuilder(imageId: id)
        
        do {
            let response = try await networkManager.fetchData(builder)
            debugPrint("✅ Success: \(id) 이미지 삭제 성공!")
            return Result<ResponseDTO, Error>.success(response)
        } catch (let error) {
            return .failure(error)
        }
    }
}
