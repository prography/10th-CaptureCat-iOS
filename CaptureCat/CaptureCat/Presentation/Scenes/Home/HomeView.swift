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
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
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
            
            if viewModel.isInitialLoading || viewModel.isRefreshing {
                ProgressView(viewModel.isRefreshing ? "새로고침 중..." : "로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.itemVMs.isEmpty {
                VStack(alignment: .center, spacing: 4) {
                    Text("아직 스크린샷이 없어요.")
                        .foregroundStyle(.text01)
                        .CFont(.headline02Bold)
                    if authViewModel.authenticationState == .guest {
                        Text("로그인 하면 스크린샷을 저장할 수 있어요! ")
                            .foregroundStyle(.text03)
                            .CFont(.body01Regular)
                        Button("로그인하기") {
                            authViewModel.authenticationState = .initial
//                            authViewModel.isLoginPresented = true
                        }
                        .primaryStyle(fillWidth: false)
                        .padding(.top, 16)
                    } else {
                        Text("임시보관함에서 스크린샷을 저장할 수 있어요!")
                            .foregroundStyle(.text03)
                            .CFont(.body01Regular)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    carouselView
                        .padding(.top, 12)
                        .frame(height: 400)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Array(viewModel.itemVMs.enumerated()), id: \.offset) { index, item in
                            Button {
                                router.push(.detail(id: item.id))
                            } label: {
                                ScreenshotItemView(viewModel: item, cornerRadius: 4) {
                                    TagFlowLayout(tags: item.tags.map { $0.name }, maxLines: 2)
                                        .padding(6)
                                }
                            }
                            .onAppear {
                                let thresholdIndex = max(0, viewModel.itemVMs.count - 5)
                                if index >= thresholdIndex && !viewModel.isLoadingPage {
                                    Task {
                                        await viewModel.loadNextPageServer()
                                        
                                        // ✅ 새로 로드된 아이템들의 이미지를 병렬로 로드
                                        await loadNewPageImages(from: thresholdIndex)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // 탭바를 고려한 하단 여백 추가
                }
            }
        }
        .task {
            // 로그인 상태 확인 후 데이터 로딩
            let isGuest = (KeyChainModule.read(key: .accessToken) == nil)
            debugPrint("🏠 HomeView onAppear - 게스트 모드: \(isGuest)")
            
            if isGuest == false {
                // 로그인 상태에서만 데이터 로딩
                await viewModel.loadScreenshots()
            } else {
                // 게스트 모드에서는 로컬 데이터만 로드
                await viewModel.loadLocalDataOnly()
            }
            
            // 데이터가 로드된 후에만 이미지 미리 로드 실행
            if !viewModel.itemVMs.isEmpty {
                await loadInitialVisibleImages()
            }
//            }
        }
        .onChange(of: viewModel.itemVMs.count) { oldCount, newCount in
            // 데이터가 새로 채워졌을 때 (빈 상태에서 데이터가 들어온 경우)
            if oldCount == 0 && newCount > 0 {
                Task {
                    await loadInitialVisibleImages()
                }
            }
        }
        .refreshable {
            // Pull to refresh (중복 실행 방지 적용)
            await viewModel.refreshScreenshots()
        }
    }
    
    private var carouselView: some View {
        Group {
            if viewModel.favoriteItemVMs.isEmpty == false {
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
                .onChange(of: viewModel.favoriteItemVMs.count) { _, newCount in
                    // 새로운 아이템이 추가되었을 때 현재 인덱스가 범위를 벗어나지 않도록 조정
                    if viewModel.currentFavoriteIndex >= newCount && newCount > 0 {
                        viewModel.onAssetChanged(to: newCount - 1)
                    }
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
        
        ScreenshotItemView(viewModel: asset) {
            EmptyView()
        }
        .overlay(
            Button {
                router.push(.favorite)
            } label: {
                Image(.favoriteList)
                    .resizable()
                    .frame(width: 32, height: 32)
            }
                .padding(.trailing, 16)
                .padding(.bottom, 12),
            alignment: .bottomTrailing
        )
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(x: xOffset, y: 0)
        .zIndex(zIndex)
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
                // 범위 제한: 0 이상, favoriteItemVMs.count - 1 이하
                let clampedDraggingItem = max(0, min(Double(viewModel.favoriteItemVMs.count - 1), newDraggingItem))
                draggingItem = clampedDraggingItem
            }
            .onEnded { value in
                isDragging = false
                
                // 드래그 완료 시에만 애니메이션 적용
                let pred = value.predictedEndTranslation.width / 100
                let targetDragging = snappedItem - pred
                
                // 인덱스 계산 및 범위 제한
                let rawIndex = Int(round(targetDragging))
                let itemCount = viewModel.favoriteItemVMs.count
                let clampedIndex = max(0, min(itemCount - 1, rawIndex))
                
                // 애니메이션과 함께 최종 위치로 이동
                withAnimation(.easeOut(duration: 0.3)) {
                    snappedItem = Double(clampedIndex)
                    draggingItem = Double(clampedIndex)
                }
                
                // 뷰모델 업데이트는 애니메이션 완료 후에 수행
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    viewModel.onAssetChanged(to: clampedIndex)
                }
            }
    }
    
    private func syncOnAppear() {
        let targetValue = Double(viewModel.currentFavoriteIndex)
        snappedItem = targetValue
        draggingItem = targetValue
    }
    
    private func syncOnChange(to newIndex: Int) {
        // 유효한 인덱스인지 확인
        guard newIndex >= 0 && newIndex < viewModel.favoriteItemVMs.count else { return }
        
        let targetValue = Double(newIndex)
        // 애니메이션 없이 즉시 동기화
        snappedItem = targetValue
        draggingItem = targetValue
    }
    
    func distance(_ item: Int) -> Double {
        // 단순한 선형 거리 계산 (순환하지 않음)
        return draggingItem - Double(item)
    }
    
    func myXOffset(_ item: Int) -> Double {
        return -distance(item) * 240  // 부호 반전으로 애니메이션 방향 수정
    }
    
    // MARK: - Image Loading Helpers
    
    /// 첫 화면에 보이는 이미지들을 병렬로 미리 로드 (안전한 버전)
    private func loadInitialVisibleImages() async {
        // 빈 배열 체크 + 이중 검증
        guard !viewModel.itemVMs.isEmpty, viewModel.itemVMs.count > 0 else {
            debugPrint("📷 로드할 이미지가 없음 (count: \(viewModel.itemVMs.count))")
            return
        }
        
        let visibleCount = min(6, viewModel.itemVMs.count)
        debugPrint("📷 초기 이미지 로딩 시작: \(visibleCount)개 (전체: \(viewModel.itemVMs.count)개)")
        
        // enumerated()를 사용해서 안전하게 접근
        let itemsToLoad = Array(viewModel.itemVMs.prefix(visibleCount))
        
        // 로드할 아이템이 실제로 있는지 한번 더 확인
        guard !itemsToLoad.isEmpty else {
            debugPrint("📷 prefix로 가져온 아이템이 없음")
            return
        }
        
        // 각 이미지를 개별 Task로 로딩
        await withTaskGroup(of: Void.self) { group in
            for (index, item) in itemsToLoad.enumerated() {
                group.addTask { [item] in
                    debugPrint("📷 이미지 로딩 시작: \(index) - ID: \(item.id)")
                    await item.loadFullImage()
                    debugPrint("✅ 이미지 로딩 완료: \(index) - ID: \(item.id)")
                }
            }
        }
        
        debugPrint("✅ 초기 이미지 로딩 전체 완료")
    }
    
    /// 새로운 페이지의 이미지들을 병렬로 로드
    private func loadNewPageImages(from startIndex: Int) async {
        let currentItems = viewModel.itemVMs
        let safeStartIndex = max(0, startIndex)
        let endIndex = min(currentItems.count, safeStartIndex + 10) // 최대 10개씩
        
        // ✅ 병렬 로딩으로 새 페이지 이미지들을 동시에 다운로드
        await withTaskGroup(of: Void.self) { group in
            for i in safeStartIndex..<endIndex {
                guard i < viewModel.itemVMs.count else { break }
                
                group.addTask {
                    await viewModel.itemVMs[i].loadFullImage()
                }
            }
        }
    }
}
