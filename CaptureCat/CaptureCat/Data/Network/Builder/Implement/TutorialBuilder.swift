//
//  TutorialBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/23/25.
//

import Foundation

struct TutorialBuilder: BuilderProtocol {
    typealias Response = ResponseDTO
    
    var path: String = PathURLType.turorial.path()
    var queries: [URLQueryItem]? = nil
    var method: HTTPMethod { .post }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
}
