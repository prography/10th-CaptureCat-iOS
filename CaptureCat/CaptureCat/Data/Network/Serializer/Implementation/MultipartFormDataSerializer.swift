//
//  MultipartFormDataSerializer.swift
//  CaptureCat
//
//  Created by minsong kim on 7/17/25.
//

import Foundation

final class MultipartFormDataSerializer: NetworkSerializable {
    private let boundary = "Boundary-\(UUID().uuidString)"
    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }
    func serialize(_ parameters: [String: Any]) async throws -> Data {
        var body = Data()
        
        debugPrint("🔍 MultipartFormDataSerializer 시작")
        debugPrint("🔍 - Boundary: \(boundary)")
        debugPrint("🔍 - Parameters 개수: \(parameters.count)")
        
        for (key, value) in parameters {
            debugPrint("🔍 - Processing key: '\(key)'")
            
            // 3-1) [MultipartFile] 배열인 경우
            if let files = value as? [MultipartFile] {
                debugPrint("🔍   - Type: [MultipartFile] 배열, 개수: \(files.count)")
                for (index, file) in files.enumerated() {
                    let partHeader = "--\(boundary)\r\nContent-Disposition: form-data; name=\"\(key)\"; filename=\"\(file.filename)\"\r\nContent-Type: \(file.mimeType)\r\n\r\n"
                    debugPrint("🔍   - File[\(index)]: filename='\(file.filename)', size=\(file.data.count) bytes")
                    debugPrint("🔍   - Header: \(partHeader.replacingOccurrences(of: "\r\n", with: "\\r\\n"))")
                    
                    body.appendString("--\(boundary)\r\n")
                    body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(file.filename)\"\r\n")
                    body.appendString("Content-Type: \(file.mimeType)\r\n\r\n")
                    body.append(file.data)
                    body.appendString("\r\n")
                }
                continue
            }
            
            // 3-2) 단일 MultipartFile
            if let file = value as? MultipartFile {
                debugPrint("🔍   - Type: 단일 MultipartFile")
                debugPrint("🔍   - filename: '\(file.filename)', size: \(file.data.count) bytes")
                if file.mimeType == "application/json", let jsonString = String(data: file.data, encoding: .utf8) {
                    debugPrint("🔍   - JSON 내용: \(jsonString)")
                }
                
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(file.filename)\"\r\n")
                body.appendString("Content-Type: \(file.mimeType)\r\n\r\n")
                body.append(file.data)
                body.appendString("\r\n")
                continue
            }
            
            // 3-3) 텍스트 파라미터
            debugPrint("🔍   - Type: 텍스트 파라미터, value: \(value)")
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        // 4) 마무리 boundary
        body.appendString("--\(boundary)--\r\n")
        
        debugPrint("🔍 MultipartFormDataSerializer 완료")
        debugPrint("🔍 - 총 Body 크기: \(body.count) bytes")
        
        return body
    }
    
    func serialize(request: URLRequest, parameters: [String: Any]) throws -> URLRequest {
        var request = request
        // Content-Type은 이미 BuilderProtocol에서 설정되므로 중복 설정 제거
        
        var body = Data()
        
        for (key, value) in parameters {
            // 1) MultipartFile 배열인 경우
            if let files = value as? [MultipartFile] {
                for file in files {
                    body.appendString("--\(boundary)\r\n")
                    body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(file.filename)\"\r\n")
                    body.appendString("Content-Type: \(file.mimeType)\r\n\r\n")
                    body.append(file.data)
                    body.appendString("\r\n")
                }
                continue
            }
            
            // 2) 단일 MultipartFile 기존 처리
            if let file = value as? MultipartFile {
                body.appendString("--\(boundary)\r\n")
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(file.filename)\"\r\n")
                body.appendString("Content-Type: \(file.mimeType)\r\n\r\n")
                body.append(file.data)
                body.appendString("\r\n")
                continue
            }
            
            // 3) 그 외 텍스트 파라미터
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        // 4) 종료 boundary
        body.appendString("--\(boundary)--\r\n")
        
        request.httpBody = body
        return request
    }
}

/// Data에 편리하게 바운더리 문자열을 붙이기 위한 extension
private extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
