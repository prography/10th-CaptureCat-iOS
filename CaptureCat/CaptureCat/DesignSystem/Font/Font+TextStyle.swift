//
//  Font+TextStyle.swift
//  CaptureCat
//
//  Created by minsong kim on 6/22/25.
//

import SwiftUI

extension Font.TextStyle {
    func toUIFontTextStyle() -> UIFont.TextStyle {
        switch self {
        case .largeTitle:
            return .largeTitle
        case .title:
            return .title1
        case .title2:
            return .title2
        case .title3:
            return .title3
        case .headline:
            return .headline
        case .subheadline:
            return .subheadline
        case .body:
            return .body
        case .callout:
            return .callout
        case .footnote:
            return .footnote
        case .caption:
            return .caption1
        case .caption2:
            return .caption2
        @unknown default:
            return .body
        }
    }
}

