//
//  UserInfoBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 8/16/25.
//

import Foundation

struct UserInfoBuilder: BuilderProtocol {
    typealias Response = LogInResponseDTO
    
    var path: String = PathURLType.userInfo.path()
    var queries: [URLQueryItem]?
    var method: HTTPMethod { .get }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
}
