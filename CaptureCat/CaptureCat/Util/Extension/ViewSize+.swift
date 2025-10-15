//
//  ViewSizeExtension.swift
//  CaptureCat
//
//  Created by minsong kim on 10/15/25.
//

import SwiftUI

// MARK: - ViewSizePreferenceKey
struct ViewSizePreferenceKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

// MARK: - View Extension
extension View {
    func readSize(onChange: @escaping (CGSize) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: ViewSizePreferenceKey.self, value: geometry.size)
            }
        )
        .onPreferenceChange(ViewSizePreferenceKey.self, perform: onChange)
    }
}
