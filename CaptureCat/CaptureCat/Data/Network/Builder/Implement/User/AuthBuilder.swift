//
//  AuthBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/16/25.
//

import Foundation

struct AuthBuilder: BuilderProtocol {
    typealias Response = LogInResponseDTO
    
    var path: String = PathURLType.auth.path()
    var queries: [URLQueryItem]?
    var method: HTTPMethod { .post }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { false }
    
    init(social: String, idToken: String?, authToken: String?, nickname: String?) {
        self.path += "/\(social)/login"
        self.parameters = ["idToken": idToken, "authToken": authToken, "nickname": nickname ?? ""]
    }
}
