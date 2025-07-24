//
//  PopularTagBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

struct PopularTagBuilder: BuilderProtocol {
    typealias Response = TagDTO
    
    var path: String = PathURLType.mostUsedTags.path()
    var queries: [URLQueryItem]? = nil
    var method: HTTPMethod { .get }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(page: Int = 0, size: Int = 10) {
        self.queries = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
    }
}
