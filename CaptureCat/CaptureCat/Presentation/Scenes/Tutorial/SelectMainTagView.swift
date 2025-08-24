//
//  SelectMainTagView.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import SwiftUI

struct SelectMainTagView: View {
    @StateObject var viewModel: SelectMainTagViewModel
    @EnvironmentObject var router: Router
    
    var body: some View {
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
                                Text(topic.localizedKey)
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
                viewModel.saveTopicLocal()
                MixpanelManager.shared.trackInterestTag(viewModel.selected.map { $0.id })
                router.push(.permission)
            }
            .primaryStyle()
            .disabled(viewModel.selected.isEmpty)
            .padding(.horizontal, 16)
        }
        .task {
            MixpanelManager.shared.trackStartView()
        }
    }
}
