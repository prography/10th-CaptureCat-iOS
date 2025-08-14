//
//  View+PopUp.swift
//  CaptureCat
//
//  Created by minsong kim on 6/23/25.
//

import SwiftUI

extension View {
    func popUp(
        isPresented: Binding<Bool>,
        title: LocalizedStringKey,
        message: LocalizedStringKey,
        cancelTitle: LocalizedStringKey,
        confirmTitle: LocalizedStringKey,
        confirmAction: @escaping () -> Void
    ) -> some View {
        modifier(
            PopUpViewModifier(
                isPresented: isPresented,
                title: title,
                message: message,
                cancelTitle: cancelTitle,
                confirmTitle: confirmTitle,
                confirmAction: confirmAction
            )
        )
    }
    
    func singlePopUp(
        isPresented: Binding<Bool>,
        title: LocalizedStringKey? = nil,
        message: LocalizedStringKey,
        cancelTitle: LocalizedStringKey) -> some View {
            modifier(
                SinglePopUpViewModifier(
                    isPresented: isPresented,
                    title: title,
                    message: message,
                    cancelTitle: cancelTitle
                )
            )
        }
}
