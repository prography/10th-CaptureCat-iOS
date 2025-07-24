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
    
    init(imageDatas: [Data],
         imageMetas: [PhotoDTO],
         jpegQuality: CGFloat = 0.8) {
        var params = [String: Any]()
        
        guard imageDatas.count == imageMetas.count else {
            debugPrint("🔴 치명적 오류: 개수 불일치 - 이미지:\(imageDatas.count), 메타:\(imageMetas.count)")
            self.parameters = [:]
            return
        }
        
        // 🔧 파일명 변환 함수 (메타데이터와 파일에서 동일하게 사용)
        func sanitizeFileName(_ fileName: String) -> String {
            let safeFileName = fileName
                .replacingOccurrences(of: " ", with: "_")
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: "\\", with: "_")
            
            let finalFileName = safeFileName.hasSuffix(".jpg") || safeFileName.hasSuffix(".jpeg")
                ? safeFileName 
                : safeFileName + ".jpg"
            
            return finalFileName
        }
        
        // 1) 메타데이터 처리 - 안전성 강화 (태그 정보 포함, 파일명 일치)
        let metaArray = imageMetas.enumerated().map { index, meta in
            let sanitizedFileName = sanitizeFileName(meta.fileName)
            
            return [
                "fileName": sanitizedFileName,  // ✅ 변환된 파일명 사용
                "captureDate": meta.createDate,
                "isBookmarked": meta.isFavorite,
                "tagNames": meta.tags  // ✅ 실제 태그 전송 활성화!
            ]
        }
        
        debugPrint("🔍 메타데이터 \(metaArray.count)개 생성 완료")
        
        do {
            let metaData = try JSONSerialization.data(withJSONObject: metaArray, options: [])
            debugPrint("✅ 메타데이터 JSON 직렬화 성공: \(metaData.count) bytes")
            params["uploadItems"] = MultipartFile(
                filename: "uploadItems.json",
                mimeType: "application/json",
                data: metaData
            )
        } catch {
            debugPrint("🔴 메타데이터 JSON 직렬화 실패: \(error)")
            params["uploadItems"] = MultipartFile(
                filename: "uploadItems.json",
                mimeType: "application/json",
                data: Data("[]".utf8)
            )
        }
        
        // 2) PNG 등이 섞여 있을 수 있는 Data를 JPEG로 변환
        let jpegDatas: [Data] = imageDatas.enumerated().compactMap { index, rawData in
            
            guard let image = UIImage(data: rawData),
                  let jpeg = image.jpegData(compressionQuality: jpegQuality)
            else {
                debugPrint("⚠️ 이미지 [\(index)] JPEG 변환 실패, 원본 데이터 사용")
                return rawData
            }
            return jpeg
        }
        
        // 3) MultipartFile로 wrapping - 파일명 안전성 확보 (메타데이터와 일치)
        let fileParts: [MultipartFile] = jpegDatas.enumerated().map { i, data in
            guard i < imageMetas.count else {
                debugPrint("🔴 인덱스 범위 초과: \(i) >= \(imageMetas.count)")
                return MultipartFile(
                    filename: "image_\(i).jpg",
                    mimeType: "image/jpeg",
                    data: data
                )
            }
            
            let originalFileName = imageMetas[i].fileName
            let finalFileName = sanitizeFileName(originalFileName)
            debugPrint("🔧 파일[\(i)]: '\(finalFileName)' (\(data.count) bytes)")
            
            return MultipartFile(
                filename: finalFileName,  // ✅ 메타데이터와 동일한 파일명
                mimeType: "image/jpeg",
                data: data
            )
        }
        
        // 최종 개수 검증 및 설정
        if metaArray.count != fileParts.count {
            debugPrint("🔴 최종 개수 불일치: 메타(\(metaArray.count)) vs 파일(\(fileParts.count))")
        } else {
            debugPrint("✅ 메타데이터와 파일 개수 일치: \(metaArray.count)개")
        }
        
        params["files"] = fileParts
        debugPrint("🔍 UploadImageBuilder 초기화 완료: JSON + \(fileParts.count)개 파일")
        
        self.parameters = params
    }
}
