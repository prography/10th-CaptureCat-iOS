//
//  SelectMainTagView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

struct SelectMainTagView: View {
    @StateObject private var viewModel = SelectMainTagViewModel()
    @State private var navigationToScreenshots = false
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("자주 캡쳐하는 이미지가 있으신가요?")
                        .CFont(.headline02Bold)
                        .foregroundStyle(.text01)
                    Text("관심 주제를 선택(5개 이하)해주시면\n캐치가 미리 태그로 만들어드려요.")
                        .CFont(.body02Regular)
                        .foregroundStyle(.text03)
                }
                .padding(.leading, 16)
                .padding(.top, 16)
                
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(viewModel.rows, id: \.self) { row in
                        HStack(spacing: 12) {
                            ForEach(row) { topic in
                                Button {
                                    viewModel.toggle(topic)
                                } label: {
                                    Text(topic.title)
                                }
                                .chipStyle(
                                    isSelected: viewModel.selected.contains(topic),
                                    selectedBackground: .primary01,
                                    selectedForeground: .white
                                )
                                
                            }
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                Spacer()
                Button(viewModel.selectionText) {
                    navigationToScreenshots = true
                    print("선택 완료 \(viewModel.selected.map(\.title))")
                }
                .primaryStyle()
                .disabled(viewModel.selected.isEmpty)
                .padding(.horizontal, 16)
            }
            .navigationDestination(isPresented: $navigationToScreenshots) {
                StartGetScreenshotView()
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}

#Preview {
    SelectMainTagView()
}
