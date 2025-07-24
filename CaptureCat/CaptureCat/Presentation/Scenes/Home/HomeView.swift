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
            
            if viewModel.isInitialLoading {
                ProgressView("로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.itemVMs.isEmpty {
                Text("저장된 스크린샷이 없습니다.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.itemVMs.enumerated()), id: \.element.id) { index, item in
                            NavigationLink {
                                DetailView(item: item)
                                    .environmentObject(viewModel)
                                    .navigationBarBackButtonHidden()
                                    .toolbar(.hidden, for: .navigationBar)
                            } label: {
                                ScreenshotItemView(viewModel: item, cornerRadius: 4) {
                                    TagFlowLayout(tags: item.tags, maxLines: 2)
                                        .padding(6)
                                }
                            }
                            .onAppear {
                                let thresholdIndex = max(0, viewModel.itemVMs.count - 5)
                                if index >= thresholdIndex && !viewModel.isLoadingPage {
                                    Task {
                                        await viewModel.loadNextPageServer()
                                        
                                        // 새로 로드된 아이템들의 이미지 로드
                                        let startIndex = max(0, thresholdIndex)
                                        for i in startIndex..<viewModel.itemVMs.count {
                                            await viewModel.itemVMs[i].loadFullImage()
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
            // 초기 데이터 로딩 (중복 방지)
            await viewModel.loadScreenshots()
            
            // 모든 아이템의 이미지 로드
            for itemVM in viewModel.itemVMs {
                await itemVM.loadFullImage()
            }
        }
        .refreshable {
            // Pull to refresh
            await viewModel.refreshScreenshots()
        }
    }
}
