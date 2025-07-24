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
    
    var body: some View {
        VStack {
            CustomNavigationBar(
                title: viewModel.mode == .batch ? "태그하기" : "태그하기 \(viewModel.progressText)",
                onBack: { router.pop() },
                actionTitle: "저장",
                onAction: {
                    Task {
                        await viewModel.save()
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
                isPresented: $viewModel.isShowingAddTagSheet
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
        .onAppear { syncOnAppear() }
        .onChange(of: viewModel.currentIndex) { _, newIndex in
            syncOnChange(to: newIndex)
        }
    }
    
    // 카드 하나를 그리는 뷰 빌더 분리
    @ViewBuilder
    private func carouselCard(at index: Int) -> some View {
        let asset = viewModel.itemVMs[index]
        let distance = distance(index)
        let scale = 1.0 - abs(distance) * 0.2
        let opacity = 1.0 - abs(distance) * 0.3
        let zIndex = 1.0 - abs(distance) * 0.1
        let xOffset = myXOffset(index)
        
        SingleCardView {
            ScreenshotItemView(viewModel: asset) {
                EmptyView()
            }
        }
        .scaleEffect(scale)
        .opacity(opacity)
        .offset(x: xOffset, y: 0)
        .zIndex(zIndex)
    }
    
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                // 옵션 1: 드래그 방향 반전 (오른쪽 드래그 = 인덱스 증가)
                draggingItem = snappedItem - value.translation.width / 100
            }
            .onEnded { value in
                withAnimation {
                    // 옵션 1: 드래그 방향 반전
                    let pred = value.predictedEndTranslation.width / 100
                    draggingItem = snappedItem - pred
                    
                    // 옵션 2: 개선된 인덱스 계산 로직
                    let rawIndex = Int(round(draggingItem))
                    let itemCount = viewModel.itemVMs.count
                    let normalizedIndex = ((rawIndex % itemCount) + itemCount) % itemCount
                    
                    snappedItem = Double(normalizedIndex)
                    draggingItem = snappedItem
                    
                    viewModel.onAssetChanged(to: normalizedIndex)
                }
            }
    }
    
    private func syncOnAppear() {
        snappedItem = Double(viewModel.currentIndex)
        draggingItem = snappedItem
    }
    
    private func syncOnChange(to newIndex: Int) {
        snappedItem = Double(newIndex)
        draggingItem = snappedItem
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
