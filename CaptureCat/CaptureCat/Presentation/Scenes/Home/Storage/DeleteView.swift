//
//  DeleteView.swift
//  CaptureCat
//
//  Created by minsong kim on 10/9/25.
//

import SwiftUI

struct DeleteView: View {
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authViewModel: AuthViewModel
    @StateObject var viewModel: DeleteViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    var body: some View {
        ZStack {
            VStack(spacing: 12) {
                navigationBar
                Divider()
                    .foregroundStyle(.divider)
                selectionBar
                ScrollView {
                    screenshotGrid
                }
                .disabled(AccountStorage.shared.isGuest == true)
            }
            
            if authViewModel.authenticationState == .guest {
                VStack {
                    navigationBar
                    Spacer()
                    
                    Button {
                        authViewModel.authenticationState = .initial
                        router.popToRoot()
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
        .popUp(
            isPresented: $viewModel.askDeletePopUp,
            title: "삭제할까요?",
            message: "\(viewModel.selectedIDs.count)개의 항목을 삭제하시겠습니까?\n삭제된 항목은 복구할 수 없습니다.",
            cancelTitle: "취소",
            confirmTitle: "삭제"
        ) {
            viewModel.deleteSelected()
        }
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
            
            Text("캡쳐 정리")
                .CFont(.headline02Bold)
                .foregroundStyle(.text02)
            Text("\(viewModel.totalCount)")
                .CFont(.headline02Regular)
                .foregroundStyle(.text03)
            Spacer()
            
            Button{
                viewModel.showDeletePopUp()
            } label: {
                Text("삭제")
                    .CFont(.subhead01Bold)
                    .foregroundStyle(viewModel.selectedIDs.isEmpty ? .gray03 : .primary01)
            }
            .disabled(viewModel.selectedIDs.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.top)
    }
    
    private var selectionBar: some View {
        HStack {
            Button {
                viewModel.toggleAllSelection()
                print("select all button tapped")
            } label: {
                HStack {
                    Image(systemName: viewModel.isAllSelected ? "checkmark.square.fill" : "square")
                        .foregroundStyle(viewModel.isAllSelected ? .primary01 : .primaryLow)
                    Text("전체 선택")
                        .CFont(.body02Regular)
                        .foregroundStyle(.text02)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 14)
    }

    private var screenshotGrid: some View {
        ZStack {
            // ✅ 기본 스크린샷 그리드
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                    PHAssetView(
                        asset: asset,
                        isSelected: viewModel.selectedIDs.contains(asset.localIdentifier),
                        isTagged: viewModel.isTaggedImage(asset.localIdentifier)
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
