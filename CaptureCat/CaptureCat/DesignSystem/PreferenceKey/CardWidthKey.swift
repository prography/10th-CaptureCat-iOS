//
//  CardWidthKey.swift
//  CaptureCat
//
//  Created by minsong kim on 10/26/25.
//

import SwiftUI

// PreferenceKey 정의
struct CardWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 260
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

