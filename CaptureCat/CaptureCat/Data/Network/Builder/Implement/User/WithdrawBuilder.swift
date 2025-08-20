//
//  WithdrawBuilder.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

import Foundation

struct WithdrawBuilder: BuilderProtocol {
    typealias Response = ResponseDTO
    
    var path: String = PathURLType.withdraw.path()
    var queries: [URLQueryItem]?
    var method: HTTPMethod { .delete }
    var parameters: [String: Any] = [:]
    let deserializer: NetworkDeserializable = JSONNetworkDeserializer(decoder: JSONDecoder())

    var useAuthorization: Bool { true }
    
    init(reason: String) {
        self.parameters = ["reason": reason]
    }
}
