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
    var useAuthorization: Bool { false } // 리프레시 시에는 Authorization 헤더 사용 안 함
    
    var parameters: [String: Any] = [:] // 빈 파라미터 (헤더로 전송)
    var serializer: NetworkSerializable = JSONNetworkSerializer()
    var deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())
    
    // 커스텀 헤더 설정
    var headers: [String: String]
    
    init(refreshToken: String) {
        self.headers = [
            "Content-Type": JSONNetworkSerializer().contentType,
            "Refresh-Token": "Bearer \(refreshToken)" // 🔑 헤더로 리프레시 토큰 전송
        ]
    }
} 
