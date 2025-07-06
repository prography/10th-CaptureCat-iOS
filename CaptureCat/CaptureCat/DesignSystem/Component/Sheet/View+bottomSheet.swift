//
//  View+bottomSheet.swift
//  CaptureCat
//
//  Created by minsong kim on 7/6/25.
//

import SwiftUI

// MARK: - View Extension
extension View {
    /// 내부 콘텐츠 높이에 따라 자동으로 올라오는 바텀 시트
    func popupBottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(BottomSheetModifier(isPresented: isPresented, sheetContent: content))
    }
}
