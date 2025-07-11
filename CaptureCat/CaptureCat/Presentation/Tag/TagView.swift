//
//  TagView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/30/25.
//

import SwiftUI
import Photos

struct TagView: View {
    @EnvironmentObject private var router: Router
    @StateObject private var viewModel: TagViewModel

    init(assets: [PHAsset]) {
        _viewModel = StateObject(wrappedValue: TagViewModel(assets: assets))
    }

    var body: some View {
        VStack {
            CustomNavigationBar(
                title: "태그하기",
                onBack: { router.pop() },
                actionTitle: "저장",
                onAction: { viewModel.save() },
                isSaveEnabled: viewModel.hasChanges
            )

            Picker("options", selection: $viewModel.selectedIndex) {
                ForEach(0..<viewModel.segments.count, id: \.self) { index in
                    Text(viewModel.segments[index])
                        .tag(index)
                        .CFont(.subhead02Bold)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)

            if viewModel.selectedIndex == 0 {
                MultiCardView {
                    Image(.accountCircle)
                        .resizable()
                        .scaledToFit()
                }
                .padding(50)
            } else {
                SingleCardView {
                }
                .padding(60)
            }

            HStack {
                Text("최근 추가한 태그")
                    .CFont(.subhead01Bold)
                Spacer()
                Text("태그는 최대 4개까지 저장할 수 있어요")
                    .CFont(.caption02Regular)
            }
            .padding(.horizontal, 16)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.displayTags, id: \.self) { tag in
                        Button {
                            viewModel.toggleTag(tag)
                        } label: {
                            Text(tag)
                        }
                        .chipStyle(isSelected: viewModel.selectedTags.contains(tag), selectedBackground: .primary01)
                    }

                    Button {
                        viewModel.addTagButtonTapped()
                    } label: {
                        Image(.plus)
                            .resizable()
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.text01)
                    }
                    .chipStyle(isSelected: false, selectedBackground: .primary01)
                }
            }
            .padding(.leading, 16)

            Spacer()
        }
        .popupBottomSheet(isPresented: $viewModel.isShowingAddTagSheet) {
            AddTagSheet(
                tags: $viewModel.tags,
                selectedTags: $viewModel.selectedTags,
                isPresented: $viewModel.isShowingAddTagSheet
            )
        }
    }
}
