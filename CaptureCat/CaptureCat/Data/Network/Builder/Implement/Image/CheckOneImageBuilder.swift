//
//  CheckOneImageBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/23/25.
//

import Foundation

// 🚫 서버 태그 추가 기능 임시 비활성화

struct CheckOneImageBuilder: BuilderProtocol {
    typealias Response = ImageDTO
    
    var path: String = PathURLType.imagePages.path()
    var queries: [URLQueryItem]? = nil
    var method: HTTPMethod { .get }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(id: String) {
        self.path += "/\(id)"
    }
}
