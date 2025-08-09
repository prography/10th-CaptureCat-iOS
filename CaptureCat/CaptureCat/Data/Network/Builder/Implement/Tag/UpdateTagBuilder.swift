//
//  UpdateTagBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

struct UpdateTagBuilder: BuilderProtocol {
    typealias Response = TagListDTO
    
    var path: String = PathURLType.imagePages.path()
    var queries: [URLQueryItem]?
    var method: HTTPMethod { .post }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(imageId: String, tags: [String]) {
        self.path += "/\(imageId)/tags"
        self.parameters = ["tagNames": tags]
    }
}
