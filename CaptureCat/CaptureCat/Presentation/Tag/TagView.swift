//
//  TagView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/30/25.
//

import SwiftUI
import Photos

struct TagView: View {
    @StateObject private var viewModel: TagViewModel
    @EnvironmentObject private var authViewModel: AuthViewModel
    @EnvironmentObject private var router: Router
    @State private var snappedItem = 0.0
    @State private var draggingItem = 0.0
    
    init(assets: [PHAsset]) {
        _viewModel = StateObject(wrappedValue: TagViewModel(assets: assets))
    }
    
    var body: some View {
        VStack {
            CustomNavigationBar(
                title: viewModel.selectedIndex == 0 ? "태그하기" : "태그하기 \(viewModel.progress)",
                onBack: { router.pop() },
                actionTitle: "저장",
                onAction: {
                    viewModel.save()
                    authViewModel.authenticationState = .signIn
                },
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
            .onChange(of: viewModel.selectedIndex) { _, _ in
                viewModel.onModeChanged()
            }
            
            if viewModel.selectedIndex == 0 {
                MultiCardView {
                    RoundedRectangle(cornerRadius: 12)
                        .phAssetImage(asset: viewModel.displayAsset!)
                }
                .padding(40)
            } else {
                carouselView
                    .padding(.vertical, 30)
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
    
    // 현재 표시되는 이미지의 인덱스 계산
    private var currentDisplayIndex: Int {
        let index = Int(round(snappedItem).remainder(dividingBy: Double(viewModel.assets.count)))
        return index >= 0 ? index : index + viewModel.assets.count
    }
    
    private var carouselView: some View {
        ZStack {
            ForEach(Array(viewModel.assets.enumerated()), id: \.element.localIdentifier) { index, asset in
                ZStack {
                    SingleCardView {
                        RoundedRectangle(cornerRadius: 12)
                            .phAssetImage(asset: asset)
                    }
                }
                .scaleEffect(1.0 - abs(distance(index) * 0.2))
                .opacity(1.0 - abs(distance(index)) * 0.3 )
                .blur(radius: blurRadius(for: index))
                .offset(x: myXOffset(index), y: 0)
                .zIndex(1.0 - abs(distance(index)) * 0.1)
            }
        }
                 .simultaneousGesture(
             DragGesture(minimumDistance: 10)
                 .onChanged { value in
                     guard abs(value.translation.width) > abs(value.translation.height) else { return }
                     draggingItem = snappedItem + value.translation.width / 100
                 }
                 .onEnded { value in
                     withAnimation {
                         draggingItem = snappedItem + value.predictedEndTranslation.width / 100
                         draggingItem = round(draggingItem).remainder(dividingBy: Double(viewModel.assets.count))
                         snappedItem = draggingItem
                         
                         // carousel 위치 변경 시 TagViewModel 업데이트
                         let newIndex = Int(round(snappedItem).remainder(dividingBy: Double(viewModel.assets.count)))
                         let normalizedIndex = newIndex >= 0 ? newIndex : newIndex + viewModel.assets.count
                         viewModel.onAssetChanged(to: normalizedIndex)
                     }
                 }
         )
         .onAppear {
             // 초기 carousel 위치를 현재 asset index로 설정
             snappedItem = Double(viewModel.currentAssetIndex)
             draggingItem = Double(viewModel.currentAssetIndex)
         }
         .onChange(of: viewModel.currentAssetIndex) { _, newIndex in
             // ViewModel에서 직접 index가 변경된 경우 carousel 위치 동기화
             snappedItem = Double(newIndex)
             draggingItem = Double(newIndex)
         }
    }
    
    func distance(_ item: Int) -> Double {
        return (draggingItem - Double(item)).remainder(dividingBy: Double(viewModel.assets.count))
    }
    
    func myXOffset(_ item: Int) -> Double {
        return distance(item) * 280
    }
    
    func blurRadius(for index: Int) -> CGFloat {
        let dist = abs(distance(index))
        // 중앙(0)에서는 blur = 0, 양옆으로 갈수록 blur 강해짐
        return min(dist * 5, 10)
    }
}
