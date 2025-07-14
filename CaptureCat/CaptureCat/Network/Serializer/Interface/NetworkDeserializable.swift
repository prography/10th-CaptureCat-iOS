//
//  NetworkDeserializable.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import Foundation

protocol NetworkDeserializable {
    func deserialize<T: Decodable>(_ data: Data) async throws -> T
}
