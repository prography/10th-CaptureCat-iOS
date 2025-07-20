//
//  CustomTabView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

enum Tab {
    case temporaryStorage
    case home
    case search
}

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
                    selectedTab = .temporaryStorage
                } label: {
                    VStack {
                        Image(selectedTab == .temporaryStorage ? .storageSelected : .storageUnselected)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30)
                        Text("임시보관함")
                            .CFont(selectedTab == .temporaryStorage ? .caption01Semibold : .caption02Regular)
                            .foregroundStyle(selectedTab == .temporaryStorage ? .text01 : .text03)
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
                            .frame(width: 30)
                        Text("홈")
                            .CFont(selectedTab == .home ? .caption01Semibold : .caption02Regular)
                            .foregroundStyle(selectedTab == .home ? .text01 : .text03)
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
                            .frame(width: 30)
                        Text("검색")
                            .CFont(selectedTab == .search ? .caption01Semibold : .caption02Regular)
                            .foregroundStyle(selectedTab == .search ? .text01 : .text03)
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
