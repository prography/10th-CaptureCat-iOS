//
//  RefreshTokenBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/25/25.
//

import Foundation

struct RefreshTokenBuilder: BuilderProtocol {
    typealias Response = ResponseDTO
    
    var path: String { PathURLType.refreshToken.path() }
    var queries: [URLQueryItem]? { nil }
    var method: HTTPMethod { .post }
    var useAuthorization: Bool { false }
    
    var parameters: [String: Any] = [:]
    var serializer: NetworkSerializable = JSONNetworkSerializer()
    var deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())
    
    // 커스텀 헤더 설정
    var headers: [String: String]
    
    init(refreshToken: String) {
        self.headers = [
            "Content-Type": JSONNetworkSerializer().contentType,
            "Refresh-Token": "\(refreshToken)"
        ]
    }
} 
