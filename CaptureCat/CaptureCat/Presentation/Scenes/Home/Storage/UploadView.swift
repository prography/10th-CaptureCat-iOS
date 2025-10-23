//
//  UploadView.swift
//  CaptureCat
//
//  Created by minsong kim on 10/9/25.
//

import SwiftUI

struct UploadView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject var viewModel: UploadViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    var body: some View {
        ZStack {
            VStack {
                navigationBar
                Divider()
                    .foregroundStyle(.divider)
                ScrollView {
                    screenshotGrid
                }
                .disabled(AccountStorage.shared.isGuest == true)
                
                Button {
                    router.push(.tag(ids: Array(viewModel.selectedIDs)))
                    viewModel.selectedIDs.removeAll()
                } label: {
                    Text("올리기 \(viewModel.selectedIDs.count)/20")
                }
                .buttonStyle(
                    PrimaryButtonStyle(cornerRadius: 4, backgroundColor: .primary01, foregroundColor: .white, verticalPadding: 16, fillWidth: true)
                )
                .padding(.horizontal, 16)
            }
            
            if authViewModel.authenticationState == .guest {
                VStack {
                    navigationBar
                    Spacer()
                    
                    Button {
                        authViewModel.authenticationState = .initial
                    } label: {
                        Text("로그인 후 이용하기")
                    }
                    .primaryStyle(fillWidth: false)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 80)
                    
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.overlayDim.opacity(0.3))
            }
        }
        .onAppear(perform: viewModel.checkPhotoPermission)
        .popUp(
            isPresented: $viewModel.showPermissionAlert,
            title: "사진 접근 권한이 필요합니다.",
            message: "스크린샷을 불러오기 위해 권한이 필요합니다.\n선택하지 않는 한 서버에 올라가지 않습니다.",
            cancelTitle: "취소",
            confirmTitle: "설정으로 이동"
        ) {
            viewModel.openAppSettings()
        }
        .toast(
            isShowing: $viewModel.showOverlimitToast,
            message: "최대 20장까지 선택할 수 있어요.",
            textColor: .white
        )
    }

    // MARK: - Sub-views
    private var navigationBar: some View {
        HStack {
            Button{
                router.pop()
                print("back")
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.text02)
            }
            
            Text("모든 캡쳐")
                .CFont(.headline02Bold)
                .foregroundStyle(.text02)
            Text(viewModel.selectedIDs.isEmpty ? "" : "\(viewModel.selectedIDs.count)")
                .CFont(.headline02Regular)
                .foregroundStyle(.text03)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top)
    }
    
    private var screenshotGrid: some View {
        ZStack {
            // ✅ 기본 스크린샷 그리드
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                    PHAssetView(
                        asset: asset,
                        isSelected: viewModel.selectedIDs.contains(asset.localIdentifier)
                    )
                    .onTapGesture {
                        viewModel.toggleSelection(of: asset)
                    }
                    .onAppear {
                        // 마지막 아이템에서 5개 전에 다음 페이지 로드
                        if viewModel.shouldLoadMore(for: asset) {
                            viewModel.loadNextPage()
                        }
                    }
                }
                
                // 더 많은 데이터가 있고 로딩 중일 때 로딩 인디케이터 표시
                if viewModel.isLoadingMore {
                    GridRow {
                        VStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("로딩 중...")
                                .CFont(.caption02Regular)
                                .foregroundColor(.text03)
                        }
                        .padding(.vertical, 20)
                        .gridCellColumns(3) // 3열 전체 차지
                    }
                }
            }
            .padding(.horizontal, 16)
            .blur(radius: authViewModel.authenticationState == .guest ? 8 : 0)
        }
    }

}
