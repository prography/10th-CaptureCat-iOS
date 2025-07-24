//
//  AddOneImageTagBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/23/25.
//

import Foundation

// 🚫 서버 태그 추가 기능 임시 비활성화
/*
struct AddOneImageTagBuilder: BuilderProtocol {
    typealias Response = ResponseDTO
    
    var path: String = PathURLType.oneImage.path()
    var queries: [URLQueryItem]? = nil
    var method: HTTPMethod { .post }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(id: String, tags: [String]) {
        self.path += "/\(id)/tags"
        self.parameters = ["tagNames": tags]
    }
}
*/
