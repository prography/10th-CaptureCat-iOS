//
//  PathURLType.swift
//  CaptureCat
//
//  Created by minsong kim on 7/16/25.
//

enum PathURLType {
    case auth
    case withdraw
    case refreshToken
    case uploadImage
    case turorial
    case imagePages
    case searchByTag
    case searchAuto
    case getTags
    case relatedTags
    case mostUsedTags
    case favorite
    case favoriteImages
    case userInfo
    
    func path() -> String {
        
        switch self {
        case .auth:
            return "/v1/auth"
        case .withdraw:
            return "/v1/user/withdraw"
        case .refreshToken:
            return "/token/reissue"
        case .uploadImage:
            return "/v1/images/upload"
        case .turorial:
            return "/v1/user/tutorialComplete"
        case .imagePages:
            return "/v1/images"
        case .searchByTag:
            return "/v1/images/search"
        case .searchAuto:
            return "/v1/search/autocomplete"
        case .getTags:
            return "/v1/tags"
        case .relatedTags:
            return "/v1/tags/related"
        case .mostUsedTags:
            return "/v1/tags/most-used"
        case .favorite:
            return "/v1/bookmarks"
        case .favoriteImages:
            return "/v1/bookmarks/images"
        case .userInfo:
            return "/v1/user/info"
        }
    }
}
