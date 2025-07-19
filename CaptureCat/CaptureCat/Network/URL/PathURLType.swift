//
//  PathURLType.swift
//  CaptureCat
//
//  Created by minsong kim on 7/16/25.
//

enum PathURLType {
    case auth
    case uploadImage
    
    func path() -> String {
        
        switch self {
        case .auth:
            return "/v1/auth"
        case .uploadImage:
            return "/v1/images/upload"
        }
    }
}
