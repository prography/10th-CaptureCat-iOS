//
//  UpdateUserTagBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 10/9/25.
//

import Foundation

struct UpdateUserTagBuilder: BuilderProtocol {
    typealias Response = UserTagDTO
    
    var path: String = PathURLType.userTagList.path()
    var queries: [URLQueryItem]?
    var method: HTTPMethod { .patch }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(newTag: String, id: Int) {
        self.parameters = ["newTagName": newTag,
                           "currentTagId": id]
    }
}
