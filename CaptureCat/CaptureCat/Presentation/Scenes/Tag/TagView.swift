//
//  TagView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/30/25.
//

import SwiftUI
import Photos

struct TagView: View {
    @StateObject var viewModel: TagViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var router: Router
    @State private var snappedItem = 0.0
    @State private var draggingItem = 0.0
    @State private var isDragging = false
    
    var body: some View {
        mainContentView
            .overlay(uploadProgressOverlay)
            .task {
                // 2) 뷰가 올라온 다음, 각 뷰모델에 이미지 로딩
                for itemVM in viewModel.itemVMs {
                    await itemVM.loadFullImage()
                }
            }
            .popupBottomSheet(isPresented: $viewModel.isShowingAddTagSheet) {
                AddTagSheet(
                    tags: $viewModel.tags,
                    selectedTags: $viewModel.selectedTags,
                    isPresented: $viewModel.isShowingAddTagSheet,
                    onAddNewTag: { newTag in
                        viewModel.addNewTag(name: newTag)
                    },
                    onDeleteTag: { tag in
                        viewModel.toggleTag(tag) // 기존 toggleTag 로직으로 태그 제거
                    }
                )
            }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack {
            navigationBarView
            
            modePickerView
            
            contentSectionView
            
            Spacer()
            
            tagSectionView
            
            Spacer()
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBarView: some View {
        CustomNavigationBar(
            title: viewModel.mode == .batch ? "태그하기" : "태그하기 \(viewModel.progressText)",
            onBack: { router.pop() },
            actionTitle: "저장",
            onAction: {
                Task {
                    if authViewModel.authenticationState == .guest {
                        await viewModel.saveToLocal()
                        authViewModel.activeSheet = nil
                    } else {
                        await viewModel.save()
                        
                        // 태그 편집 완료 알림 발송 (홈 화면 새로고침용)
                        NotificationCenter.default.post(name: .tagEditCompleted, object: nil)
                        authViewModel.activeSheet = nil
                        router.push(.completeSave(count: viewModel.itemVMs.count))
                        
                    }
                }
            },
            isSaveEnabled: viewModel.hasChanges && !viewModel.isUploading
        )
    }
    
    // MARK: - Mode Picker
    private var modePickerView: some View {
        Picker("options", selection: $viewModel.mode) {
            Text(viewModel.segments[0])
                .tag(Mode.batch)
            Text(viewModel.segments[1])
                .tag(Mode.single)
        }
        .pickerStyle(.segmented)
        .frame(width: 200)
        .onChange(of: viewModel.mode) { _, _ in
            viewModel.updateSelectedTags()
        }
    }
    
    // MARK: - Content Section
    private var contentSectionView: some View {
        Group {
            if viewModel.mode == .batch {
                batchContentView
            } else {
                singleContentView
            }
        }
    }
    
    private var batchContentView: some View {
        MultiCardView {
            if !viewModel.itemVMs.isEmpty {
                ScreenshotItemView(viewModel: viewModel.itemVMs[0]) {
                    EmptyView()
                }
            } else {
                Text("표시할 아이템이 없습니다.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(.horizontal, 40)
        .padding(.top, 12)
    }
    
    private var singleContentView: some View {
        carouselView
            .padding(.top, 12)
    }
    
    // MARK: - Tag Section
    private var tagSectionView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("최근 추가한 태그")
                    .CFont(.subhead01Bold)
                Spacer()
                Button {
                    viewModel.addTagButtonTapped()
                } label: {
                    Text("추가")
                        .CFont(.caption02Regular)
                        .foregroundStyle(.text03)
                }
            }
            .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.tags, id: \.self) { tag in
                        Button {
                            viewModel.toggleTag(tag)
                        } label: {
                            Text(tag)
                        }
                        .chipStyle(isSelected: viewModel.selectedTags.contains(tag), selectedBackground: .primary01)
                    }
                }
            }
            .padding(.leading, 16)
        }
    }
    
    
    // MARK: - Upload Progress Overlay
    private var uploadProgressOverlay: some View {
        Group {
            if viewModel.isUploading {
                uploadProgressView
            }
        }
    }
    
    private var uploadProgressView: some View {
        ZStack {
            uploadBackgroundOverlay
            uploadContentView
        }
    }
    
    private var uploadBackgroundOverlay: some View {
        Color.black.opacity(0.6)
            .ignoresSafeArea()
    }
    
    private var uploadContentView: some View {
        VStack(spacing: 16) {
            uploadProgressBar
            uploadCountText
        }
    }
    
    private var uploadProgressBar: some View {
        ProgressView(value: viewModel.uploadProgress)
            .progressViewStyle(.circular)
            .tint(.primary01)
            .frame(width: 300)
            .scaleEffect(1.2)
    }
    
    @ViewBuilder
    private var uploadCountText: some View {
        if viewModel.uploadedCount > 0 {
            Text("\(viewModel.uploadedCount)/\(viewModel.itemVMs.count) 완료")
                .CFont(.body01Regular)
                .foregroundColor(.white.opacity(0.8))
        }
    }
    
    // 현재 표시되는 이미지의 인덱스 계산 (안전한 계산)
    private var currentDisplayIndex: Int {
        let itemCount = viewModel.itemVMs.count
        
        // 아이템이 없으면 0 반환
        guard itemCount > 0 else { return 0 }
        
        let index = Int(round(snappedItem).remainder(dividingBy: Double(itemCount)))
        return index >= 0 ? index : index + itemCount
    }
    
    private var carouselView: some View {
        Group {
            if viewModel.itemVMs.isEmpty {
                // 아이템이 없는 경우 빈 상태 표시
                Text("표시할 아이템이 없습니다.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack {
                    // ID 기반 ForEach로 변경 (안정적인 렌더링)
                    ForEach(viewModel.itemVMs, id: \.id) { itemVM in
                        if let index = viewModel.itemVMs.firstIndex(where: { $0.id == itemVM.id }) {
                            carouselCard(for: itemVM, at: index)
                                .opacity(viewModel.isDeletingItem ? 0.3 : 1.0)  // 삭제 중 반투명
                        }
                    }
                    
                    // 삭제 진행률 오버레이
                    if viewModel.isDeletingItem {
                        deletionProgressOverlay
                    }
                }
                .simultaneousGesture(viewModel.isDeletingItem ? nil : dragGesture)  // 삭제 중 드래그 비활성화
                .allowsHitTesting(!viewModel.isDeletingItem)  // 삭제 중 터치 비활성화
                .onAppear {
                    syncOnAppear()
                }
                .onChange(of: viewModel.currentIndex) { _, newIndex in
                    // 드래그 중이 아닐 때만 동기화
                    if !isDragging {
                        DispatchQueue.main.async {
                            syncOnChange(to: newIndex)
                        }
                    }
                }
                .onChange(of: viewModel.shouldSyncCarousel) { _, _ in
                    // 삭제 후 캐러셀 상태 동기화
                    DispatchQueue.main.async {
                        syncCarouselAfterDeletion()
                    }
                }
            }
        }
    }
    
    // 카드 하나를 그리는 뷰 빌더 (ID 기반, 안정성 강화)
    @ViewBuilder
    private func carouselCard(for itemVM: ScreenshotItemViewModel, at index: Int) -> some View {
        let distance = distance(index)
        let scale = max(0.8, 1.0 - abs(distance) * 0.2)
        let opacity = max(0.3, 1.0 - abs(distance) * 0.3)
        let zIndex = 1.0 - abs(distance) * 0.1
        let xOffset = myXOffset(index)
        
        SingleCardView(
            onDelete: {
                guard !viewModel.isDeletingItem else {
                    return
                }
                // 안전한 삭제 (큐 시스템 사용)
                safeDeleteItem(at: index)
            }
        ) {
            ScreenshotItemView(viewModel: itemVM) {
                EmptyView()
            }
            .overlay(
                Button {
                    // 삭제 중이 아닐 때만 즐겨찾기 토글 허용
                    guard !viewModel.isDeletingItem else { return }
                    
                    // 즐겨찾기 토글
                    if let currentIndex = viewModel.itemVMs.firstIndex(where: { $0.id == itemVM.id }) {
                        viewModel.toggleFavorite(at: currentIndex)
                    }
                } label: {
                    Image(itemVM.isFavorite ? .selectedFavorite : .unselectedFavorite)
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
        .padding(.horizontal, 50)
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(x: xOffset, y: 0)
        .zIndex(zIndex)
        .animation(.none, value: draggingItem) // 드래그 중 애니메이션 비활성화
        .animation(.easeInOut(duration: 0.3), value: viewModel.isDeletingItem) // 삭제 상태 애니메이션
    }
    
    // 삭제 진행률 표시 오버레이
    private var deletionProgressOverlay: some View {
        VStack {
            Spacer()
            HStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(0.8)
                
                Text(viewModel.deletionProgress)
                    .CFont(.body01Regular)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.7))
            .cornerRadius(20)
            .padding(.bottom, 50)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isDeletingItem)
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                // 삭제 중에는 드래그 제스쳐 비활성화
                guard !viewModel.isDeletingItem else { return }
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
                
                // 아이템이 없으면 드래그 제스쳐 무시 (크래시 방지)
                let itemCount = viewModel.itemVMs.count
                guard itemCount > 0 else {
                    return
                }
                
                // 드래그 완료 시에만 애니메이션 적용
                let pred = value.predictedEndTranslation.width / 100
                let targetDragging = snappedItem - pred
                
                // 안전한 인덱스 계산 (0으로 나누기 방지)
                let rawIndex = Int(round(targetDragging))
                let normalizedIndex = ((rawIndex % itemCount) + itemCount) % itemCount
                
                // 최종 인덱스 범위 검증
                let safeIndex = max(0, min(normalizedIndex, itemCount - 1))
                
                // 애니메이션과 함께 최종 위치로 이동
                withAnimation(.easeOut(duration: 0.3)) {
                    snappedItem = Double(safeIndex)
                    draggingItem = Double(safeIndex)
                }
                
                // 뷰모델 업데이트는 애니메이션 완료 후에 수행 (인덱스 재검증)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    // 애니메이션 완료 후에도 아이템이 존재하는지 확인
                    if safeIndex < viewModel.itemVMs.count {
                        viewModel.onAssetChanged(to: safeIndex)
                    }
                }
            }
    }
    
    private func syncOnAppear() {
        let targetValue = Double(viewModel.currentIndex)
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
        let itemCount = Double(viewModel.itemVMs.count)
        
        // 아이템이 없는 경우 안전하게 처리
        guard itemCount > 0 else { return 0 }
        
        let rawDistance = draggingItem - Double(item)
        
        // 개선된 거리 계산 (순환 거리)
        let normalizedDistance = ((rawDistance.remainder(dividingBy: itemCount)) + itemCount).remainder(dividingBy: itemCount)
        
        // 가장 가까운 거리 선택 (앞으로 가거나 뒤로 가거나)
        return normalizedDistance > itemCount / 2 ? normalizedDistance - itemCount : normalizedDistance
    }
    
    func myXOffset(_ item: Int) -> Double {
        return -distance(item) * 260  // 부호 반전으로 애니메이션 방향 수정
    }
    
    /// 아이템 안전 삭제 (큐 시스템 사용)
    private func safeDeleteItem(at index: Int) {
        debugPrint("🗑️ TagView: 삭제 요청 [\(index)/\(viewModel.itemVMs.count)]")
        
        // ViewModel의 큐 시스템으로 삭제 처리
        viewModel.deleteItem(at: index)
    }
    
    /// 삭제 후 캐러셀 상태 동기화
    private func syncCarouselAfterDeletion() {
        let itemCount = viewModel.itemVMs.count
        
        // 모든 아이템이 삭제된 경우
        guard itemCount > 0 else {
            withAnimation(.easeOut(duration: 0.3)) {
                snappedItem = 0
                draggingItem = 0
            }
            return
        }
        
        // 현재 인덱스로 캐러셀 위치 조정
        let newCurrentIndex = viewModel.currentIndex
        let targetValue = Double(newCurrentIndex)
        
        // 부드러운 애니메이션으로 위치 조정
        withAnimation(.easeOut(duration: 0.3)) {
            snappedItem = targetValue
            draggingItem = targetValue
        }
    }
}
