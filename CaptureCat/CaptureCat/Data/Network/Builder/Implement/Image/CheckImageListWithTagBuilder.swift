//
//  CheckImageListWithTagBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

struct CheckImageListWithTagBuilder: BuilderProtocol {
    typealias Response = ImagListDTO
    
    var path: String = PathURLType.searchByTag.path()
    var queries: [URLQueryItem]? = []
    var method: HTTPMethod { .get }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(page: Int, size: Int, tagNames: [String]) {
        for tag in tagNames {
            self.queries?.append(URLQueryItem(name: "tagNames", value: tag))
        }
        
        self.queries?.append(URLQueryItem(name: "page", value: String(page)))
        self.queries?.append(URLQueryItem(name: "size", value: String(size)))
    }
}
