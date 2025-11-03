//
//  HomeView2.swift
//  CaptureCat
//
//  Created by minsong kim on 9/11/25.
//

import SwiftUI

struct HomeView: View {
    @AppStorage(LocalUserKeys.didImageDeleteBottomSheetPresented.rawValue) private var hasSeenSheet: Bool = false
    
    @EnvironmentObject var router: Router
    @EnvironmentObject var viewModel: HomeViewModel
    
    @State private var showChannel = false
    @State private var showImageSettingSheet = false
    @State private var isMenuPresented = false
    @State private var showToast = false
    @State private var toastMessage = ""
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 12)
                
                HStack {
                    TabSection(
                        tags: viewModel.allTags,
                        selectedTag: Binding(
                            get: { viewModel.selectedTag },
                            set: { viewModel.selectedTag = $0 }
                        ),
                        showAll: true
                    ) { newTag in
                        if let tag = newTag {
                            Task {
                                await viewModel.selectTag(tag)
                            }
                        } else {
                            Task {
                                await viewModel.clearAllSelections()
                            }
                        }
                        
                        Task {
                            await viewModel.refreshData()
                        }
                    }
                    
                    Divider()
                        .frame(width: 2, height: 16)
                        .background(.divider)
                    
                    Button {
                        router.push(.tagSetting)
                    } label: {
                        Image(.toc)
                            .resizable()
                            .frame(width: 32, height: 32)
                            .opacity(0.9)
                    }
                    .background(.clear)
                    .padding(.trailing, 4)
                    .padding(.bottom, 2)
                }
                .padding(.horizontal, 8)
                
                csBanner
                    .padding(.bottom, 8)
                
                ZStack {
                    if viewModel.allTags.isEmpty {
                        VStack(spacing: 8) {
                            Spacer()
                            Text("아직 태그가 없어요.")
                                .CFont(.headline02Bold)
                                .foregroundStyle(.text03)
                            Text("스크린샷을 태그해 정리해보세요!")
                                .CFont(.body01Regular)
                                .foregroundStyle(.text03)
                            Spacer()
                        }
                        .multilineTextAlignment(.center)
                    } else {
                        selectedTagResults
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                    isMenuPresented.toggle()
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.primary01))
                    .shadow(radius: 8, y: 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .padding(.trailing, 20)
            .padding(.bottom, 24)
            
            if isMenuPresented {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.95)) {
                        isMenuPresented = false
                    }
                }
            }
            
            if isMenuPresented {
                VStack(spacing: 18) {
                    MenuCard(
                        uploadAction: {
                            router.push(.uploadPhotos)
                            closeMenu()
                        },
                        organizeAction: {
                            router.push(.deletePhotos)
                            closeMenu()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .scale.combined(with: .opacity))
                    )
                    
                    Spacer()
                        .frame(height: 56) // plus 버튼 높이만큼 여백
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 20)
                .padding(.bottom, 12) // 기존 bottom padding + 버튼 높이 + 여백
                
                // 닫기 원형 버튼 - plus 버튼과 동일한 위치에 배치
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.95)) {
                        isMenuPresented = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .CFont(.subhead01Bold)
                        .foregroundStyle(.primary01)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.white))
                        .shadow(radius: 8, y: 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .padding(.trailing, 20)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemBackground))
        .task {
            await viewModel.refreshData()
        }
        .onAppear {
            showImageSettingSheet = !hasSeenSheet
        }
        .onReceive(viewModel.toastPublisher) { message in
            toastMessage = message
            showToast = true
        }
        .toast(isShowing: $showToast, message: toastMessage, fillWidth: false)
        .sheet(isPresented: $showChannel) {
            let countryCode = Locale.current.region?.identifier ?? "KR"
            
            if countryCode == "KR" {
                SafariView(url: KakaoChannelManger.safariURL!)
            } else {
                MailComposerViewController(recipients: ["capturecat77@gmail.com"])
            }
        }
        .sheet(isPresented: $showImageSettingSheet, content: {
            DeletePermissionSheet(
                isPresented: $showImageSettingSheet,
                goToSetting: {
                    hasSeenSheet = true
                    UserDefaults.standard.deleteOriginalsAfterSave = true
                    Task {
                        await viewModel.deleteOriginalsIfEnabled(viewModel.savedImages)
                    }
                },
                later: {
                    hasSeenSheet = true
                    UserDefaults.standard.deleteOriginalsAfterSave = false
                }
            )
            .presentationDetents([.height(300)])
        })
        .onReceive(viewModel.$savedImages) { _ in
            Task {
                await viewModel.deleteOriginalsIfEnabled(viewModel.savedImages)
            }
        }
    }
    
    func closeMenu() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.95)) {
            isMenuPresented = false
        }
    }
    
    private var header: some View {
        HStack {
            Image(.mainLogo)
            Spacer()
            Button { router.push(.setting) } label: {
                Image(.my)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var csBanner: some View {
        Button {
            showChannel = true
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("채팅으로 오류 제보하기")
                        .CFont(.subhead01Bold)
                        .foregroundStyle(.primary01)
                        .padding(.top, 8)
                    Text("보내주신 내용은 모두 확인하고 답변드려요")
                        .CFont(.caption02Regular)
                        .foregroundStyle(.text02)
                }
                Spacer()
                Image(.bannerCatch)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.primaryLow)
        )
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - 선택된 태그 결과
    private var selectedTagResults: some View {
        VStack(spacing: 16) {
            if viewModel.isLoadingScreenshots {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.8)
                    Spacer()
                }
                .padding(.vertical, 20)
            } else {
                ScrollView {
                    LazyVGrid(columns: gridColumns, spacing: 4) {
                        ForEach(viewModel.filteredScreenshots) { item in
                            Button {
                                router.push(.detail(id: item.id))
                            } label: {
                                ScreenshotItemView(viewModel: item, cornerRadius: 4) {
                                    EmptyView()
                                }
                            }
                            .onAppear {
                                // 마지막 아이템에 도달했을 때 더 많은 데이터 로드
                                if viewModel.shouldLoadMore(currentItem: item) {
                                    viewModel.loadMoreScreenshots()
                                }
                            }
                        }
                        
                        // 추가 로딩 인디케이터
                        if viewModel.isLoadingMore {
                            VStack {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Spacer()
                                }
                                .padding(.vertical, 10)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100)
                }
//                .refreshable {
//                    await viewModel.refreshData()
//                }
            }
        }
    }
    
    // MARK: - Grid Layout
    private let gridColumns = [
        GridItem(.adaptive(minimum: 100), spacing: 4)
    ]
}
