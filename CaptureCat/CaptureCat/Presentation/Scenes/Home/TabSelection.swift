//
//  HomeView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

struct TabSection: View {
    let tags: [String]                        // 태그 이름들
    @Binding var selectedTag: String?         // 선택된 태그 (nil = 전체)
    var showAll: Bool = true
    var onCategoryChanged: ((String?) -> Void)? = nil
    
    // "전체" 포함 여부에 따라 표시할 배열 생성
    private var displayed: [String?] {
        showAll ? [nil] + tags.map { Optional($0) } : tags.map { Optional($0) }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(displayed, id: \.self) { tag in
                        tabItem(tag)
                            .padding(.horizontal, 4)
                            .id(tag ?? "ALL") // nil이면 "ALL"로 아이디 부여
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let newID = tag   // nil = 전체
                                withAnimation(.easeInOut) {
                                    selectedTag = newID
                                }
                                onCategoryChanged?(newID)
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo(newID ?? "ALL", anchor: .center)
                                }
                            }
                    }
                    .padding(.horizontal, 2)
                }
            }
            .onChange(of: selectedTag) { _, newID in
                withAnimation(.easeInOut) {
                    proxy.scrollTo(newID ?? "ALL", anchor: .center)
                }
            }
        }
    }
    
    @ViewBuilder
    private func tabItem(_ tag: String?) -> some View {
        let isSelected = selectedTag == tag || (tag == nil && selectedTag == nil)
        
        VStack(spacing: 8) {
            Text(tag ?? "전체")  // nil이면 "전체" 표시
                .CFont(.subhead02Bold)
                .foregroundStyle(isSelected ? .primary01 : .text03)
            Rectangle()
                .fill(isSelected ? .primary01 : .clear)
                .frame(height: 3)
        }
    }
}
