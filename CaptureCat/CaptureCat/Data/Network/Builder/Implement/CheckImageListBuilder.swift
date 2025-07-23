//
//  CheckImageListBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/23/25.
//

import Foundation

struct CheckImageListBuilder: BuilderProtocol {
    typealias Response = ImagListDTO
    
    var path: String = PathURLType.oneImage.path()
    var queries: [URLQueryItem]? = nil
    var method: HTTPMethod { .get }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(page: Int, size: Int) {
        self.queries = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "size", value: String(size))
        ]
    }
}
