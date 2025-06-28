//
//  StartGetScreenshotView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI
import Photos

struct StartGetScreenshotView: View {
    @StateObject private var manager = ScreenshotManager()
    @State private var showOverlimitToast = false
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 3)
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("시작하기 전에 \n\(manager.totalCount)장의 스크린샷이 있어요.")
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
                
                LazyVGrid(
                    columns: columns,
                    spacing: 4
                ) {
                    ForEach(manager.assets, id: \.localIdentifier) { asset in
                        ScreenshotThumbnailView(
                            asset: asset,
                            isSelected: manager.selectedIDs.contains(asset.localIdentifier)
                        )
                        .onTapGesture {
                            manager.toggleSelection(of: asset)
                            
                            if manager.selectedIDs.count > 20 {
                                manager.toggleSelection(of: asset)
                                withAnimation {
                                    showOverlimitToast = true
                                }
                            }
                        }
                    }
                }
            }
            Spacer()
            Button("정리하기 \(manager.selectedIDs.count)/20") {
                print("선택")
            }
            .primaryStyle()
            .disabled(manager.selectedIDs.isEmpty)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .toast(isShowing: $showOverlimitToast, message: "최대 20장까지 선택할 수 있어요.", textColor: .error)
    }
}
