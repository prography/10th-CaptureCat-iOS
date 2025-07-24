//
//  RelatedTagListBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

struct RelatedTagListBuilder: BuilderProtocol {
    typealias Response = TagDTO
    
    var path: String = PathURLType.relatedTags.path()
    var queries: [URLQueryItem]? = nil
    var method: HTTPMethod { .get }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(page: Int, size: Int, tags: [String]) {
        self.queries = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
        for tag in tags {
            self.queries?.append(URLQueryItem(name: "tagNames", value: tag))
        }
    }
}
