//
//  NetworkSerializable.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import Foundation

protocol NetworkSerializable {
    func serialize(_ parameters: [String: Any]) async throws -> Data
}
