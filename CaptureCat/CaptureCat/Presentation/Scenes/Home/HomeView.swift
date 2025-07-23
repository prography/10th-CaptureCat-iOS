//
//  HomeView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI
import Photos

struct HomeView: View {
    @EnvironmentObject var router: Router
    @StateObject var viewModel: HomeViewModel
    
    // Grid 레이아웃
    private let columns = [
        GridItem(.adaptive(minimum: 150), spacing: 12)
    ]
    
    var body: some View {
        VStack {
            // — Header
            HStack {
                Image(.mainLogo)
                Spacer()
                Button { router.push(.setting) } label: {
                    Image(.accountCircle)
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
            
            if viewModel.itemVMs.isEmpty {
                Text("저장된 스크린샷이 없습니다.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.itemVMs.enumerated()), id: \.element.id) { index, item in
                            NavigationLink {
                                DetailView(item: item)
                                    .navigationBarBackButtonHidden()
                                    .toolbar(.hidden, for: .navigationBar)
                            } label: {
                                ScreenshotItemView(viewModel: item, cornerRadius: 4) {
                                    HStack(spacing: 4) {
                                        ForEach(item.tags, id: \.self) { tag in
                                            Text(tag)
                                                .CFont(.caption01Semibold)
                                                .padding(.horizontal, 7.5)
                                                .padding(.vertical, 4.5)
                                                .background(Color.overlayDim)
                                                .foregroundColor(.white)
                                                .cornerRadius(4)
                                        }
                                    }
                                    .padding(6)
                                }
                            }
                            .onAppear {
                                let thresholdIndex = viewModel.itemVMs.count - 5
                                if index >= thresholdIndex {
                                    Task {
                                        await viewModel.loadNextPageServer()
                                        for (index, itemVM) in viewModel.itemVMs.enumerated() {
                                            if index > thresholdIndex + 5 {
                                                await itemVM.loadFullImage()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            // 스마트 로딩 (로그인 상태 자동 분기)
            await viewModel.loadScreenshots()
            
            for (_, itemVM) in viewModel.itemVMs.enumerated() {
                await itemVM.loadFullImage()
            }
        }
    }
}
