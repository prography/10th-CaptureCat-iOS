//
//  ImageService.swift
//  CaptureCat
//
//  Created by minsong kim on 7/17/25.
//

import Foundation

final class ImageService {
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager) {
        self.networkManager = networkManager
    }
    
    func uploadImages(imageDatas: [Data], imageMetas: [ImageMetaDTO]) async -> Result<ResponseDTO, NetworkError> {
        let builder = UploadImageBuilder(imageDatas: imageDatas, imageMetas: imageMetas)
        
        do {
            let response = try await networkManager.fetchData(builder)
            debugPrint("✅ Success: 이미지 파일들 업로드 성공!")
            return Result<ResponseDTO, NetworkError>.success(response)
        } catch(let error) {
            debugPrint("🔥 Error:\(error)")
            return .failure(NetworkError.unauthorized)
        }
    }
}
