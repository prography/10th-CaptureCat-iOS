//
//  StartGetScreenshotView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

struct StartGetScreenshotView: View {
    @StateObject var viewModel: StartGetScreenshotViewModel
    @EnvironmentObject private var router: Router

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                header
                screenshotGrid
            }

            Spacer()

            actionButton
        }
        .toast(
            isShowing: $viewModel.showOverlimitToast,
            message: "최대 10장까지 선택할 수 있어요.",
            textColor: .error
        )
    }

    // MARK: Sub-views
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("시작하기 전에 \n\(viewModel.totalCount)장의 스크린샷이 있어요.")
                .CFont(.headline02Bold)
                .foregroundStyle(.text01)

            Text("나중에도 저장할 수 있으니 먼저 필요한 이미지만 골라보세요.")
                .CFont(.body02Regular)
                .foregroundStyle(.text03)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var screenshotGrid: some View {
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                PHAssetView(
                    asset: asset,
                    isSelected: viewModel.selectedIDs.contains(asset.localIdentifier)
                )
                .onTapGesture { viewModel.toggleSelection(of: asset) }
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
    }

    private var actionButton: some View {
        Button("정리하기 \(viewModel.selectedIDs.count)/10") {
            viewModel.tutorialCompleted()
            router.push(.tag(ids: Array(viewModel.selectedIDs)))
        }
        .primaryStyle()
        .disabled(viewModel.selectedIDs.isEmpty)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
