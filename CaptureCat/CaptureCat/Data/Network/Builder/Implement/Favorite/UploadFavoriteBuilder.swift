//
//  UploadFavoriteBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

struct UploadFavoriteBuilder: BuilderProtocol {
    typealias Response = ResponseDTO
    
    var path: String = PathURLType.favorite.path()
    var queries: [URLQueryItem]?
    var method: HTTPMethod { .post }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(imageId: String) {
        self.queries = [URLQueryItem(name: "imageId", value: imageId)]
    }
}
