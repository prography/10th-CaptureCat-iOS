//
//  BaseURLType.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import Foundation

enum BaseURLType {
    case production
    case development
    
    var url: URL? {
        switch self {
        case .production:
            return URL(string: "https://api.capture-cat.com")
        case .development:
            return URL(string: "https://dev.api.capture-cat.com")
        }
    }
}
