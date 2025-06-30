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
        title: String,
        message: String,
        cancelTitle: String,
        confirmTitle: String,
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
        title: String? = nil,
        message: String,
        cancelTitle: String) -> some View {
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

