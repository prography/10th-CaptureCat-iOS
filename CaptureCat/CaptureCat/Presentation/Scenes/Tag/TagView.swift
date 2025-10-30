//
//  TagView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/30/25.
//

import SwiftUI
import Photos

struct TagView: View {
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var router: Router
    @StateObject var viewModel: TagViewModel
    @State private var snappedItem = 0.0
    @State private var draggingItem = 0.0
    @State private var isDragging = false
    @State private var isDeletingWithGesture = false // 삭제 제스처 진행 상태 추적
    @State private var horizontalPadding: CGFloat = 16
    @State private var currentID: String?
    
    var body: some View {
        mainContentView
            .overlay(uploadProgressOverlay)
            .task {
                for itemVM in viewModel.itemVMs {  await itemVM.loadFullImage() }
            }
            .sheet(isPresented: $viewModel.isShowingAddTagSheet, content: {
                AddTagSheet(
                    tags: $viewModel.tags,
                    selectedTags: $viewModel.selectedTags,
                    isPresented: $viewModel.isShowingAddTagSheet,
                    onAddNewTag: { newTag in viewModel.addNewTag(name: newTag) },
                    onDeleteTag: { tag in viewModel.toggleTag(tag) }
                )
                .presentationDetents([.height(190)])
            })
            .navigationDestination(isPresented: $viewModel.pushNext) {
                UploadCompleteView(count: viewModel.itemVMs.count)
                    .navigationBarBackButtonHidden()
                    .toolbar(.hidden, for: .navigationBar)
            }
            .toast(isShowing: $viewModel.canSelectTag, message: "태그는 4개까지 추가할 수 있습니다.", cornerRadius: 0)
            .onChange(of: viewModel.mode) { _, _ in
                viewModel.updateSelectedTags()
            }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack(alignment: .center, spacing: 16) {
            navigationBarView
            modeTab
                .padding(.bottom, 16)
            contentSectionView
            if viewModel.selectedTags.isEmpty {
                addTagButtonView
            } else {
                allTagListViewEditMode
            }
            tagSectionView
                .padding(.bottom, 8)
            saveButton
        }
    }
    
    // MARK: - Navigation Bar
    private var navigationBarView: some View {
        HStack {
            Button{
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.text02)
            }
            
            Text("태그하기")
                .CFont(.headline02Bold)
                .foregroundStyle(.text02)
            Text(viewModel.mode == .batch ? "" : "\(viewModel.progressText)")
                .CFont(.headline02Regular)
                .foregroundStyle(.text03)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top)
    }
    
//    // MARK: - Mode Picker
    private var modeTab: some View {
        HStack(spacing: 0) {
            tabButton(.batch)
            tabButton(.single)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .zIndex((viewModel.isDeletingItem || isDeletingWithGesture) ? 0 : 1000) // 삭제 중이거나 삭제 제스처 중일 때는 가려지고, 평상시에는 최상위에서 클릭 가능
        .allowsHitTesting(!(viewModel.isDeletingItem || isDeletingWithGesture)) // 삭제 중이거나 삭제 제스처 중일 때는 터치 비활성화
        .opacity((viewModel.isDeletingItem || isDeletingWithGesture) ? 0.3 : 1.0) // 삭제 중이거나 삭제 제스처 중일 때 반투명으로 표시
        .animation(.easeInOut(duration: 0.3), value: viewModel.isDeletingItem || isDeletingWithGesture) // 부드러운 상태 전환
    }
    
    private func tabButton(_ tab: Mode) -> some View {
        let isSelected = viewModel.mode == tab
        
        return Button {
            withAnimation(.easeInOut) {
                viewModel.mode = tab
            }
        } label: {
            VStack(spacing: 8) {
                Text(viewModel.segments[tab.rawValue])
                    .CFont(.subhead01Bold)
                    .foregroundColor(isSelected ? .primary01 : .text03)
                Rectangle()
                    .fill(isSelected ? .primary01 : .divider)
                    .frame(height: isSelected ? 2 : 0.5)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
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
            }
        }
        .padding(.horizontal, 40)
    }
    
    private var singleContentView: some View {
        carouselView
            .zIndex((viewModel.isDeletingItem || isDeletingWithGesture) ? 1000 : 0)
    }
    
    // MARK: - Tag Section
    private var addTagButtonView: some View {
        Button {
            viewModel.addTagButtonTapped()
        } label: {
            Text("추가하기")
        }
        .chipStyle(
            isSelected: true,
            selectedBackground: .gray02,
            selectedForeground: .text01,
            selectedBorderColor: .divider,
            icon: Image(.plus)
        )
        .frame(height: 50)
    }
    
    private var allTagListViewEditMode: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                ZStack {
                    // 부모(스크롤 영역) 너비만큼 자리 차지하는 투명 뷰
                    Color.clear
                        .frame(width: geo.size.width)

                    HStack(spacing: 6) {
                        ForEach(Array(viewModel.selectedTags), id: \.self) { tag in
                            Button {
                                withAnimation(.easeInOut) {
                                    viewModel.toggleTag(tag)
                                }
                            } label: {
                                Text(tag)
                            }
                            .chipStyle(
                                isSelected: true,
                                selectedBackground: .secondary01,
                                icon: Image(.xmark)
                            )
                        }
                        
                        Button {
                            viewModel.addTagButtonTapped()
                        } label: {
                            Image(.plus)
                                .resizable()
                                .frame(width: 14, height: 14)
                        }
                        .chipStyle(
                            isSelected: true,
                            selectedBackground: .gray02,
                            selectedForeground: .text01,
                            selectedBorderColor: .divider,
                            icon: nil
                        )
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .frame(height: 50) // chip 높이에 맞게
    }
    
    private var tagSectionView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("최근 추가한 태그")
                    .CFont(.subhead01Bold)
                Spacer()
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
                        .chipStyle(
                            isSelected: viewModel.selectedTags.contains(tag),
                            selectedBackground: .clear,
                            selectedForeground: .gray04,
                            unselectedBorderColor: .divider,
                            icon: viewModel.selectedTags.contains(tag) ? Image(.check) : nil
                        )
                    }
                }
            }
            .padding(.leading, 16)
        }
    }
    
    private var saveButton: some View {
        Button {
            Task {
                await viewModel.save(isGuest: authViewModel.authenticationState == .guest)
                
                router.push(.completeSave(count: viewModel.itemVMs.count))
            }
        } label: {
            Text("저장하기")
        }
        .buttonStyle(
            PrimaryButtonStyle(cornerRadius: 4, backgroundColor: .primary01, foregroundColor: .white, verticalPadding: 14, fillWidth: true)
        )
        .padding(.horizontal, 16)
    }
    
    // MARK: - Upload Progress Overlay
    private var uploadProgressOverlay: some View {
        Group {
            if viewModel.isUploading { uploadProgressView }
        }
    }
    
    private var uploadProgressView: some View {
        ZStack {
            uploadBackgroundOverlay
            uploadContentView
        }
    }
    
    private var uploadBackgroundOverlay: some View {
        Color.black.opacity(0.6).ignoresSafeArea()
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
        guard itemCount > 0 else { return 0 }
        let index = Int(round(snappedItem).remainder(dividingBy: Double(itemCount)))
        return index >= 0 ? index : index + itemCount
    }
    
    private var carouselView: some View {
        ZStack {
            carouselScrollView
            
            if viewModel.isDeletingItem {
                deletionProgressOverlay
            }
        }
        .allowsHitTesting(!viewModel.isDeletingItem)  // 삭제 중 터치 비활성화
        .onChange(of: viewModel.shouldSyncCarousel) { _, _ in
            // 삭제 후 캐러셀 상태 동기화
            DispatchQueue.main.async {
                syncCarouselAfterDeletion()
            }
        }
    }
    
    private var carouselScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(viewModel.itemVMs, id: \.id) { itemVM in
                    carouselItemView(for: itemVM)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, horizontalPadding)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $currentID)
        .onChange(of: currentID) { _, newValue in
            // scrollPosition이 바뀔 때마다 호출됨
            guard let id = newValue,
                  let index = viewModel.itemVMs.firstIndex(where: { $0.id == id }) else { return }
            viewModel.onAssetChanged(to: index)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.itemVMs.count)
        .disabled(viewModel.isDeletingItem)
        .opacity(viewModel.isDeletingItem ? 0.3 : 1.0)
    }
    
    @ViewBuilder
    private func carouselItemView(for itemVM: ScreenshotItemViewModel) -> some View {
        if let index = viewModel.itemVMs.firstIndex(where: { $0.id == itemVM.id }) {
            carouselCard(for: itemVM, at: index)
                .scrollTransition(axis: .horizontal) { content, phase in
                    content
                        .scaleEffect(phase.isIdentity ? 1.0 : 0.75)
                        .opacity(phase.isIdentity ? 1.0 : 0.7)
                }
                .id(itemVM.id)
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .onAppear {
                                // 카드 너비 측정
                                horizontalPadding = (UIScreen.main.bounds.width - geo.size.width) / 2
                            }
                    }
                )
        }
    }
    
    // 카드 하나를 그리는 뷰 빌더 (ID 기반, 안정성 강화)
    @ViewBuilder
    private func carouselCard(for itemVM: ScreenshotItemViewModel, at index: Int) -> some View {
        SingleCardView(
            onDelete: {
                guard !viewModel.isDeletingItem else {
                    return
                }
                // 안전한 삭제 (큐 시스템 사용)
                safeDeleteItem(at: index)
            },
            onDragStateChanged: { isDragging in
                // 삭제 제스처 진행 상태 업데이트
                isDeletingWithGesture = isDragging
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
                        withAnimation(.none) {
                            viewModel.toggleFavorite(at: currentIndex)
                        }
                    }
                } label: {
                    Image(itemVM.isFavorite ? .favoriteSelected : .favoriteUnselected)
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding(3)
                }
                    .padding(16),
                alignment: .bottomLeading
            )
        }
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
