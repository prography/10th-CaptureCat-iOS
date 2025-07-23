//
//  StorageView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/29/25.
//

import SwiftUI

struct StorageView: View {
    @StateObject var viewModel: StorageViewModel
    @EnvironmentObject private var router: Router
    @EnvironmentObject private var authViewModel: AuthViewModel

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    var body: some View {
        ZStack {
            ScrollView {
                header
                selectionBar
                screenshotGrid
            }
            .disabled(AccountStorage.shared.isGuest == true) // ✅ 스크롤 자체를 막음

            if AccountStorage.shared.isGuest == true {
                VStack {
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
        .toast(
            isShowing: $viewModel.showOverlimitToast,
            message: "최대 20장까지 선택할 수 있어요.",
            textColor: .error
        )
        .toast(
            isShowing: $viewModel.showCountToast,
            message: "\(viewModel.selectedIDs.count)/20",
            fillWidth: false,
            cornerRadius: 24
        )
        .singlePopUp(
            isPresented: $viewModel.showDeleteFailurePopup,
            message: "삭제할 이미지를 선택해 주세요.",
            cancelTitle: "다음"
        )
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
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("임시보관함")
                    .CFont(.headline02Bold)
                    .foregroundStyle(.text01)
                
                Text("\(viewModel.totalCount)장의 스크린샷이 있어요.")
                    .CFont(.body02Regular)
                    .foregroundStyle(.text01)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Button {
                router.push(.tag(ids: Array(viewModel.selectedIDs)))
            } label: {
                Text("다음")
            }
            .primaryTextStyle(isEnabled: viewModel.selectedIDs.count > 0 && viewModel.selectedIDs.count <= 20)
        }
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
            Button {
                viewModel.showDeletePopUp()
            } label: {
                Text("선택 삭제")
                    .CFont(.body02Regular)
                    .foregroundStyle(.text03)
            }
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
            .blur(radius: AccountStorage.shared.isGuest == true ? 8 : 0)
        }
    }

}
