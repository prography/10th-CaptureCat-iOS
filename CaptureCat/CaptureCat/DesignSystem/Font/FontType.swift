//
//  FontType.swift
//  CaptureCat
//
//  Created by minsong kim on 6/22/25.
//

enum FontType {
    case pretendardBold
    case pretendardSemiBold
    case pretendardRegular
    
    var name: String {
        switch self {
        case .pretendardBold:
            return "Pretendard-Bold"
        case .pretendardSemiBold:
            return "Pretendard-SemiBold"
        case .pretendardRegular:
            return "Pretendard-Regular"
        }
    }
}
