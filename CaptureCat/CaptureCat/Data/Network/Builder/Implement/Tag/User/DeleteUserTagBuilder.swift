//
//  DeleteUserTagBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 10/9/25.
//

import Foundation

struct DeleteUserTagBuilder: BuilderProtocol {
    typealias Response = ResponseDTO
    
    var path: String = PathURLType.userTagList.path()
    var queries: [URLQueryItem]?
    var method: HTTPMethod { .delete }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(tagId: String) {
        self.queries = [URLQueryItem(name: "tagId", value: tagId)]
    }
}
