//
//  JSONNetworkSerializer.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import Foundation

struct JSONNetworkSerializer: NetworkSerializable {
    var contentType: String {
        "application/json"
    }
    
    init() {}
    
    func serialize(_ parameters: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: parameters)
    }
}
