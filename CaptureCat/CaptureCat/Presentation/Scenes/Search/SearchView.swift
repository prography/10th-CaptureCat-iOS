//
//  SearchView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI

struct SearchView: View {
//    @StateObject private var dataManager = ScreenshotDataManager()
//    @State private var searchText: String = ""
//    
//    // 검색어에 따라 필터링된 배열
//    @State private var items: [ScreenshotItem] = []
//    
//    // 그리드 레이아웃 정의
//    private let columns = [
//        GridItem(.adaptive(minimum: 150), spacing: 12)
//    ]
    
    var body: some View {
        Text("검색 탭입니다.")
//        NavigationStack {
//            ScrollView {
//                LazyVGrid(columns: columns, spacing: 12) {
//                    ForEach($items) { item in
//                        NavigationLink {
//                            DetailView(item: item)
//                                .navigationBarBackButtonHidden()
//                                .toolbar(.hidden, for: .navigationBar)
//                        } label: {
//                            ScreenshotView(item: item)
//                                .cornerRadius(4)
//                        }
//                    }
//                }
//                .padding()
//            }
//        }
//        .searchable(text: $searchText, prompt: "태그 이름으로 검색해 보세요")
//        // 검색어가 바뀔 때마다 데이터 매니저에 요청
//        .onChange(of: searchText) { newTag in
//            dataManager.fetchItems(with: newTag)
//        }
//        // 데이터 매니저의 Published 를 구독
//        .onReceive(dataManager.$screenshotItems) { newItems in
//            self.items = newItems
//        }
        // 뷰가 처음 뜰 때 전체 로딩
//        .task {
//            dataManager.fetchItems(with: "")
//        }
    }
}
