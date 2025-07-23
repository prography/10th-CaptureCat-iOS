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
                        ForEach(viewModel.itemVMs) { item in
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
                        }
                    }
                    .padding()
                }
            }
        }
        .task {
            // 스마트 로딩 (로그인 상태 자동 분기)
            debugPrint("🏠 HomeView task 시작")
            await viewModel.loadScreenshots()
            
            // ✅ 업데이트 완료 후 다시 확인
            debugPrint("🏠 loadScreenshots 완료 후 아이템 개수: \(viewModel.itemVMs.count)")
            
            // 썸네일 로드 (fullImage가 아니라 thumbnail)
            for (index, itemVM) in viewModel.itemVMs.enumerated() {
                debugPrint("🏠 아이템[\(index)] 썸네일 로드 시작 - ID: \(itemVM.id)")
                await itemVM.loadFullImage()
            }
            debugPrint("🏠 HomeView task 완료")
        }
    }
}
