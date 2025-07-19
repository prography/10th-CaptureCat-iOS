//
//  UploadImageBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/17/25.
//

import UIKit

struct UploadImageBuilder: BuilderProtocol {
    typealias Response = ResponseDTO
    
    var path: String { PathURLType.uploadImage.path() }
    var queries: [URLQueryItem]? { nil }
    var method: HTTPMethod { .post }
    var useAuthorization: Bool { true }
    
    var parameters: [String: Any]
    // multipart serializer 사용
    var serializer: NetworkSerializable = MultipartFormDataSerializer()
    var deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())
    
    init(imageDatas: [Data], imageMetas: [ImageMetaDTO], jpegQuality: CGFloat = 0.8) {
        var params = [String: Any]()
        
        // 1) 메타데이터 처리 (이전과 동일)
        let metaArray = imageMetas.map { [
            "fileName": $0.fileName,
            "captureDate": $0.captureDate,
            "tagNames": $0.tagNames
        ] }
        let metaData = try? JSONSerialization.data(withJSONObject: metaArray, options: [])
        params["uploadItems"] = MultipartFile(
            filename: "file",
            mimeType: "application/json",
            data: metaData ?? Data()
        )
        
        // 2) PNG 등이 섞여 있을 수 있는 Data를 JPEG로 변환
        let jpegDatas: [Data] = imageDatas.compactMap { rawData in
            guard let image = UIImage(data: rawData),
                  let jpeg = image.jpegData(compressionQuality: jpegQuality)
            else {
                // 디코딩 실패 시 원본 Data를 그대로 쓰고 싶다면 rawData 리턴
                return rawData
            }
            return jpeg
        }
        
        // 3) MultipartFile로 wrapping
        let fileParts: [MultipartFile] = jpegDatas.enumerated().map { i, data in
            MultipartFile(
                filename: imageMetas[i].fileName, // 필요 시 .jpg로 확장자 바꿔도 OK
                mimeType: "image/jpeg",
                data: data
            )
        }
        params["files"] = fileParts
        
        self.parameters = params
    }
}

struct ImageMetaDTO {
    let fileName: String
    let captureDate: String
    let tagNames: [String]
}
