//
//  HomeView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

struct TabSection: View {
    let tags: [Tag]                           // 태그 객체들
    @Binding var selectedTag: Tag?            // 선택된 태그 (nil = 전체)
    var showAll: Bool = true
    var onCategoryChanged: ((Tag?) -> Void)? = nil
    
    // "전체" 포함 여부에 따라 표시할 배열 생성
    private var displayed: [Tag?] {
        showAll ? [nil] + tags.map { Optional($0) } : tags.map { Optional($0) }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(displayed, id: \.self) { tag in
                        tabItem(tag)
                            .padding(.top, 5)
                            .padding(.horizontal, 8)
                            .id(tag?.id ?? -1) // nil이면 -1로 아이디 부여
                            .contentShape(Rectangle())
                            .onTapGesture {
                                let newTag = tag   // nil = 전체
                                withAnimation(.easeInOut) {
                                    selectedTag = newTag
                                }
                                onCategoryChanged?(newTag)
                                withAnimation(.easeInOut) {
                                    proxy.scrollTo(newTag?.id ?? -1, anchor: .center)
                                }
                            }
                    }
                }
            }
            .onChange(of: selectedTag) { _, newTag in
                withAnimation(.easeInOut) {
                    proxy.scrollTo(newTag?.id ?? -1, anchor: .center)
                }
            }
        }
    }
    
    @ViewBuilder
    private func tabItem(_ tag: Tag?) -> some View {
        let isSelected = selectedTag == tag || (tag == nil && selectedTag == nil)
        
        VStack(spacing: 10) {
            Text(tag?.name ?? (NSLocalizedString("전체", comment: "TabSelection")))  // nil이면 "전체" 표시, Tag 객체면 name 사용
                .CFont(.subhead01Bold)
                .foregroundStyle(isSelected ? .primary01 : .text03)
            Rectangle()
                .fill(isSelected ? .primary01 : .clear)
                .frame(height: 3)
        }
    }
}
