//
//  DetailView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import SwiftUI

struct DetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var item: ScreenshotItem
    @State private var isShowingAddTagSheet: Bool = false
    @State private var tempSelectedTags: Set<String> = []
    @State private var isDeleted: Bool = false
    
    var body: some View {
        ZStack {
            Color.secondary01
                .ignoresSafeArea()
            
            VStack {
                CustomNavigationBar(title: item.createDate, onBack: { dismiss() }, color: .white)
                    .padding(.top, 10)
                ZStack(alignment:.bottomLeading) {
                    item.imageData
                        .toImage(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .padding()
                    
                    HStack(spacing: 4) {
                        ForEach(item.tags, id: \.self) { tag in
                            Text(tag)
                                .CFont(.caption01Semibold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.overlayDim)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                    }
                    .padding(.bottom, 32)
                    .padding(.horizontal, 16)
                }
                Spacer()
                bottomBar
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
        }
        .popupBottomSheet(isPresented: $isShowingAddTagSheet) {
            AddTagSheet(
                tags: $item.tags,
                selectedTags: $tempSelectedTags,
                isPresented: $isShowingAddTagSheet
            )
        }
        .popUp(
            isPresented: $isDeleted,
            title: "삭제할까요?",
            message: "1개의 항목을 삭제하시겠습니까?\n삭제시 복구할 수 없습니다.",
            cancelTitle: "취소",
            confirmTitle: "삭제"
        ) {
            print("삭제")
            dismiss()
        }
        .onAppear {
            tempSelectedTags = Set(item.tags)
        }
    }
    
    var bottomBar: some View {
        HStack {
            Spacer()
            Button {
                isShowingAddTagSheet = true
            } label: {
                VStack {
                    Image(.editSquare)
                    Text("태그 편집")
                        .CFont(.body02Regular)
                }
            }
            .foregroundStyle(.white)
            Spacer()
            Button {
                withAnimation {
                    isDeleted = true
                }
            } label: {
                VStack {
                    Image(.delete2)
                    Text("삭제")
                        .CFont(.body02Regular)
                }
            }
            .foregroundStyle(.white)
            Spacer()
        }
    }
}
