//
//  NetworkError.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import Foundation

enum NetworkError: Error {
    case urlNotFound
    case badRequest
    case unauthorized
    case forBidden
    case responseNotFound
    case tooManyRequests
    case internalServerError
    case unknown(Int)
}
