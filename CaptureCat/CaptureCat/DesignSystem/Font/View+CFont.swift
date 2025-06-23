//
//  View+CFont.swift
//  CaptureCat
//
//  Created by minsong kim on 6/22/25.
//

import SwiftUI

extension View {
    func CFont(_ font: CFont) -> some View {
        modifier(CFontModifier(font: font))
    }
}
