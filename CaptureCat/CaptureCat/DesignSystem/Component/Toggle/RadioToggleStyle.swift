//
//  RadioButtonStyle.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI

struct RadioToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack {
                configuration.label
                    .CFont(.body01Regular)
                    .foregroundStyle(.text01)
                Spacer()
                Image(configuration.isOn ? .radioSelected : .radio)
            }
            .padding()
            .background(.gray01)
            .clipShape(RoundedRectangle(cornerRadius: 8))               // 내용도 둥글게 자르고
            .overlay(                                                  // 둥근 테두리 오버레이
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        configuration.isOn ? Color.text01 : Color.gray01,
                        lineWidth: 1
                    )
            )
        }
    }
}
