//
//  TagEditView.swift
//  CaptureCat
//
//  Created by minsong kim on 10/9/25.
//

import SwiftUI

struct TagEditView: View {
    @EnvironmentObject var router: Router
    @ObservedObject var viewModel: TagSettingViewModel
    
    // 선택된 태그가 있는지 확인하는 computed property
    private var hasSelectedTags: Bool {
        !viewModel.selectedTagIds.isEmpty
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            navigationBar
            Divider()
                .foregroundStyle(.divider)
            tagListView
            Spacer()
            
            HStack {
                Button {
                    viewModel.selectAllTags()
                } label: {
                    Text("전체삭제")
                }
                .buttonStyle(
                    PrimaryButtonStyle(
                        cornerRadius: 4,
                        backgroundColor: .gray02,
                        foregroundColor: .text02,
                        verticalPadding: 20,
                        fillWidth: true
                    )
                )
                
                Button {
                    viewModel.deleteSelectedTags()
                } label: {
                    Text("삭제하기")
                }
                .buttonStyle(
                    PrimaryButtonStyle(
                        cornerRadius: 4,
                        backgroundColor: hasSelectedTags ? .primary01 : .gray04,
                        foregroundColor: hasSelectedTags ? .white : .gray06,
                        verticalPadding: 20,
                        fillWidth: true
                    )
                )
                .disabled(!hasSelectedTags)
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            Task {
                await viewModel.loadTags()
            }
        }
    }
    
    private var navigationBar: some View {
        HStack {
            Button{
                router.pop()
                print("back")
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(.text02)
            }
            
            Text("태그 편집")
                .CFont(.headline02Bold)
                .foregroundStyle(.text02)
        }
        .padding(.horizontal, 16)
        .padding(.top)
    }
    
    private var tagListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.tags, id: \.id) { tag in
                    HStack {
                        Button {
                            viewModel.toggleSelection(for: tag)
                        } label: {
                            Image(systemName: viewModel.isSelected(tag) ? "checkmark.square.fill" : "square")
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(viewModel.isSelected(tag) ? .primary01 : .primaryLow)
                        }
                        .buttonStyle(.plain)
                        
                        Text(tag.name)
                            .CFont(.body01Regular)
                            .foregroundStyle(.text01)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 48) // 셀 높이
                    .contentShape(Rectangle())
                    
                    // 인셋된 구분선 느낌 (왼쪽 여백 맞추기)
                    Divider()
                        .padding(.horizontal, 16)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 0)
        }
    }
}
