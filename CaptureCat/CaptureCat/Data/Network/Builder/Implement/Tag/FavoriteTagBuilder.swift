//
//  FavoriteTagBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 10/9/25.
//

import Foundation

struct FavoriteTagBuilder: BuilderProtocol {
    typealias Response = TagDTO
    
    var path: String = PathURLType.favoriteTags.path()
    var queries: [URLQueryItem]?
    var method: HTTPMethod { .get }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(page: Int = 0, size: Int = 100) {
        self.queries = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
    }
}
