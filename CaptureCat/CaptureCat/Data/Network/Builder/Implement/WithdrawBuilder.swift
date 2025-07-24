//
//  SingOutBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

struct SingOutBuilder: BuilderProtocol {
    typealias Response = ResponseDTO
    
    var path: String = PathURLType.auth.path()
    var queries: [URLQueryItem]? = nil
    var method: HTTPMethod { .delete }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
}
