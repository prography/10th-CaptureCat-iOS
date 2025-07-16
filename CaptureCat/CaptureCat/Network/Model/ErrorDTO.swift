//
//  ErrorDTO.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import Foundation

struct ErrorDTO: Decodable {
    let resultType: String
    let error: ErrorType
    
    struct ErrorType: Decodable {
        let code: String
        let message: String
    }
}
