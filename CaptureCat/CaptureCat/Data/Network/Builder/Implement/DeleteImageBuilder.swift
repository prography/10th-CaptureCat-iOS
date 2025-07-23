//
//  DeleteImageBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

struct DeleteImageBuilder: BuilderProtocol {
    typealias Response = ResponseDTO
    
    var path: String = PathURLType.imagePages.path()
    var queries: [URLQueryItem]? = nil
    var method: HTTPMethod { .delete }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(imageId: String) {
        self.path += "/\(imageId)"
    }
}
