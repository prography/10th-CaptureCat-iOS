//
//  CustomTabView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

struct CustomTabView: View {
    @Binding var selectedTab: Tab
    @State private var isTapped: Bool = false
    
    var body: some View {
        VStack {
            Divider()
                .foregroundStyle(.divider)
            HStack {
                Spacer()
                Button {
                    selectedTab = .favorite
                } label: {
                    VStack {
                        Image(selectedTab == .favorite ? .favoriteSelected : .favoriteUnselected)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32)
                    }
                }
                Spacer()
                Button {
                    selectedTab = .home
                } label: {
                    VStack {
                        Image(selectedTab == .home ? .homeSelected : .homeUnselected)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32)
                    }
                }
                Spacer()
                Button {
                    selectedTab = .search
                } label: {
                    VStack {
                        Image(selectedTab == .search ? .searchSelected : .searchUnselected)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32)
                    }
                    
                }
                Spacer()
            }
        }
        .background(Color.white)
    }
}

#Preview {
    @Previewable @State var tab = Tab.search
    CustomTabView(selectedTab: $tab)
}
