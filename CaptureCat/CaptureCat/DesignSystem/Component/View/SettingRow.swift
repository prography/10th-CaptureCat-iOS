//
//  SettingRow.swift
//  CaptureCat
//
//  Created by minsong kim on 8/22/25.
//

impodrt swiftUI

struct SettingRow: View {
    let title: LocalizedStringKey
    
    var body: some View {
        HStack {
            Text(title)
                .CFont(.body01Regular)
                .foregroundStyle(Color.text01).frame(maxWidth: .infinity, minHeight: 16, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
            Spacer()
            Image(.arrowForward)
                .foregroundStyle(.text03)
                .padding(.trailing, 16)
        }
    }
}
