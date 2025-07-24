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
    @State private var snappedItem = 0.0
    @State private var draggingItem = 0.0
    @State private var isDragging = false
    
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
                    carouselView
                        .padding(.top, 12)
                        .frame(height: 400)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.itemVMs.enumerated()), id: \.offset) { index, item in
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
                                        
                                        // 새로 로드된 아이템들의 이미지 로드 (안전한 범위 체크)
                                        let currentItems = viewModel.itemVMs
                                        let startIndex = max(0, thresholdIndex)
                                        let endIndex = min(currentItems.count, startIndex + 10) // 최대 10개씩만 로드
                                        
                                        for i in startIndex..<endIndex {
                                            // 인덱스가 여전히 유효한지 확인
                                            if i < viewModel.itemVMs.count {
                                                await viewModel.itemVMs[i].loadFullImage()
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
            // 초기 데이터 로딩 (중복 방지)
            await viewModel.loadScreenshots()
            
            // 모든 아이템의 이미지 로드 (안전한 방식)
            let currentItems = Array(viewModel.itemVMs)
            for itemVM in currentItems {
                await itemVM.loadFullImage()
            }
        }
        .refreshable {
            // Pull to refresh
            await viewModel.refreshScreenshots()
        }
    }
    
    private var carouselView: some View {
        ZStack {
            ForEach(viewModel.favoriteItemVMs.indices, id: \.self) { idx in
                carouselCard(at: idx)
            }
        }
        .simultaneousGesture(dragGesture)
        .onAppear {
            syncOnAppear()
        }
        .onChange(of: viewModel.currentFavoriteIndex) { _, newIndex in
            // 드래그 중이 아닐 때만 동기화
            if !isDragging {
                DispatchQueue.main.async {
                    syncOnChange(to: newIndex)
                }
            }
        }
    }
    
    // 카드 하나를 그리는 뷰 빌더 분리
    @ViewBuilder
    private func carouselCard(at index: Int) -> some View {
        let asset = viewModel.favoriteItemVMs[index]
        let distance = distance(index)
        let scale = max(0.8, 1.0 - abs(distance) * 0.2)
        let opacity = max(0.3, 1.0 - abs(distance) * 0.3)
        let zIndex = 1.0 - abs(distance) * 0.1
        let xOffset = myXOffset(index)
        
        SingleCardView() {
            ScreenshotItemView(viewModel: asset) {
                EmptyView()
            }
            .overlay(
                Button {
                    //TODO: 즐겨찾기 페이지로 이동
                } label: {
                    Image(.selectedFavorite)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(3)
                        .background(.overlayDim)
                        .clipShape(Circle())
                }
                    .padding(16),
                alignment: .bottomTrailing
            )
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(x: xOffset, y: 0)
        .zIndex(zIndex)
        .animation(.none, value: draggingItem) // 드래그 중 애니메이션 비활성화
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                
                // 드래그 시작 표시
                if !isDragging {
                    isDragging = true
                }
                
                // 드래그 중에는 애니메이션 없이 직접 값 변경
                let newDraggingItem = snappedItem - value.translation.width / 100
                draggingItem = newDraggingItem
            }
            .onEnded { value in
                isDragging = false
                
                // 드래그 완료 시에만 애니메이션 적용
                let pred = value.predictedEndTranslation.width / 100
                let targetDragging = snappedItem - pred
                
                // 인덱스 계산
                let rawIndex = Int(round(targetDragging))
                let itemCount = viewModel.itemVMs.count
                let normalizedIndex = ((rawIndex % itemCount) + itemCount) % itemCount
                
                // 애니메이션과 함께 최종 위치로 이동
                withAnimation(.easeOut(duration: 0.3)) {
                    snappedItem = Double(normalizedIndex)
                    draggingItem = Double(normalizedIndex)
                }
                
                // 뷰모델 업데이트는 애니메이션 완료 후에 수행
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    viewModel.onAssetChanged(to: normalizedIndex)
                }
            }
    }
    
    private func syncOnAppear() {
        let targetValue = Double(viewModel.currentFavoriteIndex)
        snappedItem = targetValue
        draggingItem = targetValue
    }
    
    private func syncOnChange(to newIndex: Int) {
        let targetValue = Double(newIndex)
        // 애니메이션 없이 즉시 동기화
        snappedItem = targetValue
        draggingItem = targetValue
    }
    
    func distance(_ item: Int) -> Double {
        let rawDistance = draggingItem - Double(item)
        let itemCount = Double(viewModel.itemVMs.count)
        
        // 개선된 거리 계산 (순환 거리)
        let normalizedDistance = ((rawDistance.remainder(dividingBy: itemCount)) + itemCount).remainder(dividingBy: itemCount)
        
        // 가장 가까운 거리 선택 (앞으로 가거나 뒤로 가거나)
        return normalizedDistance > itemCount / 2 ? normalizedDistance - itemCount : normalizedDistance
    }
    
    func myXOffset(_ item: Int) -> Double {
        return -distance(item) * 240  // 부호 반전으로 애니메이션 방향 수정
    }
}
