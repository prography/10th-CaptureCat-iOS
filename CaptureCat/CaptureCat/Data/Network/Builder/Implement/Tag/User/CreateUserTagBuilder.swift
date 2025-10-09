//
//  CreateUserTagBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 10/8/25.
//

import Foundation

struct CreateUserTagBuilder: BuilderProtocol {
    typealias Response = UserTagDTO
    
    var path: String = PathURLType.userTag.path()
    var queries: [URLQueryItem]?
    var method: HTTPMethod { .post }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(tagName: String) {
        self.queries = [URLQueryItem(name: "tagName", value: tagName)]
    }
}
