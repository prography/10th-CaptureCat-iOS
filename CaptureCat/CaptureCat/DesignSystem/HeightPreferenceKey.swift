//
//  HeightPreferenceKey.swift
//  CaptureCat
//
//  Created by minsong kim on 7/7/25.
//

import SwiftUI

// 1. 콘텐츠 높이를 전달받기 위한 PreferenceKey
struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        // 여러 뷰가 있을 때는 최대 높이를 사용
        value = max(value, nextValue())
    }
}
