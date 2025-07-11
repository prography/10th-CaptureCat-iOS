//
//  StorageView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/29/25.
//

import SwiftUI

struct StorageView: View {
    @StateObject private var viewModel = StorageViewModel()
    @EnvironmentObject private var router: Router

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)

    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                header
                selectionBar
                screenshotGrid
            }
            Spacer()
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
            confirmTitle: "삭제") {
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
                router.push(.tag(assets: viewModel.selectedAssets()))
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
        LazyVGrid(columns: columns, spacing: 4) {
            ForEach(viewModel.assets, id: \.localIdentifier) { asset in
                ScreenshotThumbnailView(
                    asset: asset,
                    isSelected: viewModel.selectedIDs.contains(asset.localIdentifier)
                )
                .onTapGesture {
                    viewModel.toggleSelection(of: asset)
                }
            }
        }
    }
}
