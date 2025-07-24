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
        VStack {
            CustomNavigationBar(
                title: viewModel.mode == .batch ? "태그하기" : "태그하기 \(viewModel.progressText)",
                onBack: { router.pop() },
                actionTitle: "저장",
                onAction: {
                    Task {
                        await viewModel.save()
                        
                        // 태그 편집 완료 알림 발송 (홈 화면 새로고침용)
                        NotificationCenter.default.post(name: .tagEditCompleted, object: nil)
                        
                        authViewModel.authenticationState = .signIn
                        router.popToRoot()
                    }
                },
                isSaveEnabled: viewModel.hasChanges
            )
            
            Picker("options", selection: $viewModel.mode) {
                Text(viewModel.segments[0])
                    .tag(TagViewModel.Mode.batch)   // ⬅️ Mode.batch
                Text(viewModel.segments[1])
                    .tag(TagViewModel.Mode.single)  // ⬅️ Mode.single
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .onChange(of: viewModel.mode) { _, _ in
                viewModel.updateSelectedTags()   // 모드별 태그 초기화
                viewModel.hasChanges = false
            }
            
            if viewModel.mode == .batch {
                MultiCardView {
                    ScreenshotItemView(viewModel: viewModel.itemVMs[0]) {
                        EmptyView()
                    }
                }
                .padding(.horizontal, 40)
                .padding(.top, 12)
            } else {
                carouselView
                    .padding(.top, 12)
            }
            Spacer()
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
            
            Spacer()
        }
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
    
    // 현재 표시되는 이미지의 인덱스 계산
    private var currentDisplayIndex: Int {
        let index = Int(round(snappedItem).remainder(dividingBy: Double(viewModel.itemVMs.count)))
        return index >= 0 ? index : index + viewModel.itemVMs.count
    }
    
    private var carouselView: some View {
        ZStack {
            ForEach(viewModel.itemVMs.indices, id: \.self) { idx in
                carouselCard(at: idx)
            }
        }
        .simultaneousGesture(dragGesture)
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
    }
    
    // 카드 하나를 그리는 뷰 빌더 분리
    @ViewBuilder
    private func carouselCard(at index: Int) -> some View {
        let asset = viewModel.itemVMs[index]
        let distance = distance(index)
        let scale = max(0.8, 1.0 - abs(distance) * 0.2)
        let opacity = max(0.3, 1.0 - abs(distance) * 0.3)
        let zIndex = 1.0 - abs(distance) * 0.1
        let xOffset = myXOffset(index)
        
        SingleCardView(
            onDelete: {
                viewModel.deleteItem(at: index)
            }
        ) {
            ScreenshotItemView(viewModel: asset) {
                EmptyView()
            }
            .overlay(
                Button {
                    viewModel.toggleFavorite(at: index)
                } label: {
                    Image(viewModel.itemVMs[index].isFavorite ? .selectedFavorite : .unselectedFavorite)
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
        let rawDistance = draggingItem - Double(item)
        let itemCount = Double(viewModel.itemVMs.count)
        
        // 개선된 거리 계산 (순환 거리)
        let normalizedDistance = ((rawDistance.remainder(dividingBy: itemCount)) + itemCount).remainder(dividingBy: itemCount)
        
        // 가장 가까운 거리 선택 (앞으로 가거나 뒤로 가거나)
        return normalizedDistance > itemCount / 2 ? normalizedDistance - itemCount : normalizedDistance
    }
    
    func myXOffset(_ item: Int) -> Double {
        return -distance(item) * 280  // 부호 반전으로 애니메이션 방향 수정
    }
}
