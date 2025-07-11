//
//  CFont.swift
//  CaptureCat
//
//  Created by minsong kim on 6/22/25.
//

import SwiftUI

enum CFont {
    case headline01Bold
    case headline01Regular
    case headline02Bold
    case headline02Regular
    case headline03Bold
    case headline03Regular
    case subhead01Bold
    case subhead02Bold
    case subhead03Bold
    case body01Regular
    case body02Regular
    case caption01Semibold
    case caption02Regular
    
    var textStyle: Font.TextStyle {
        switch self {
        case .headline01Bold:
            return .headline
        case .headline01Regular:
            return .headline
        case .headline02Bold:
            return .headline
        case .headline02Regular:
            return .headline
        case .headline03Bold:
            return .headline
        case .headline03Regular:
            return .headline
        case .subhead01Bold:
            return .subheadline
        case .subhead02Bold:
            return .subheadline
        case .subhead03Bold:
            return .subheadline
        case .body01Regular:
            return .body
        case .body02Regular:
            return .body
        case .caption01Semibold:
            return .caption
        case .caption02Regular:
            return .caption2
        }
    }
    
    var fontType: FontType {
        switch self {
        case .headline01Bold:
            return .pretendardBold
        case .headline01Regular:
            return .pretendardRegular
        case .headline02Bold:
            return .pretendardBold
        case .headline02Regular:
            return .pretendardRegular
        case .headline03Bold:
            return .pretendardBold
        case .headline03Regular:
            return .pretendardRegular
        case .subhead01Bold:
            return .pretendardBold
        case .subhead02Bold:
            return .pretendardBold
        case .subhead03Bold:
            return .pretendardBold
        case .body01Regular:
            return .pretendardRegular
        case .body02Regular:
            return .pretendardRegular
        case .caption01Semibold:
            return .pretendardSemiBold
        case .caption02Regular:
            return .pretendardRegular
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .headline01Bold:
            return 24
        case .headline01Regular:
            return 24
        case .headline02Bold:
            return 20
        case .headline02Regular:
            return 20
        case .headline03Bold:
            return 18
        case .headline03Regular:
            return 18
        case .subhead01Bold:
            return 16
        case .subhead02Bold:
            return 14
        case .subhead03Bold:
            return 12
        case .body01Regular:
            return 16
        case .body02Regular:
            return 14
        case .caption01Semibold:
            return 12
        case .caption02Regular:
            return 12
        }
    }
    
    var lineHeight: CGFloat {
        switch self {
        case .headline01Bold:
            return 32
        case .headline01Regular:
            return 32
        case .headline02Bold:
            return 28
        case .headline02Regular:
            return 28
        case .headline03Bold:
            return 26
        case .headline03Regular:
            return 26
        case .subhead01Bold:
            return 24
        case .subhead02Bold:
            return 22
        case .subhead03Bold:
            return 20
        case .body01Regular:
            return 24
        case .body02Regular:
            return 22
        case .caption01Semibold:
            return 20
        case .caption02Regular:
            return 20
        }
    }
}

struct CFontModifier: ViewModifier {
    let font: CFont
    
    func body(content: Content) -> some View {
        let appliedSize = font.fontSize
        let spacing = font.lineHeight - appliedSize
        
        return content
            .font(.custom(font.fontType.name, size: appliedSize, relativeTo: font.textStyle))
            .lineSpacing(spacing)
    }
}
