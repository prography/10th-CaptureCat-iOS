//
//  SearchAutoBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 8/31/25.
//

import Foundation

struct SearchAutoBuilder: BuilderProtocol {
    typealias Response = SearchDTO
    
    var path: String = PathURLType.searchAuto.path()
    var queries: [URLQueryItem]?
    var method: HTTPMethod { .get }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(keyword: String, size: Int = 10) {
        self.queries = [
            URLQueryItem(name: "keyword", value: keyword),
            URLQueryItem(name: "size", value: String(size))
        ]
    }
}
