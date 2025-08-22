//
//  TagSettingView.swift
//  CaptureCat
//
//  Created by minsong kim on 8/21/25.
//

import SwiftUI

struct TagSettingView: View {
    @EnvironmentObject var router: Router
//    @StateObject var viewModel: TagSettingViewModel
    @State private var isDisabled = true
    @State private var searchTag: String = ""
    @State private var selectedTag: Tag = Tag(id: 1, name: "태그 1")
    @State private var tagEditBottomSheet: Bool = false
    
    @State var tags: [Tag] = [Tag(id: 1, name: "태그 1"), Tag(id: 2, name: "태그 2")]
    
    var body: some View {
        VStack(spacing: 16) {
            navigationBar
            Divider()
                .foregroundStyle(.divider)
            searchBar
            
            tagListView
        }
        .onAppear {
            UITextField.appearance().clearButtonMode = .whileEditing
        }
        .sheet(isPresented: $tagEditBottomSheet, content: {
            NavigationStack {
                EditTagSheet(
                    tag: $selectedTag,
                    isPresented: $tagEditBottomSheet,
                    onAddNewTag: { newTag in print(newTag) }
                )
                .presentationDetents([ .height(180) ])
            }
        })
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
            
            Text("태그 설정")
                .CFont(.headline02Bold)
                .foregroundStyle(.text02)
            Text("\(tags.count)/30")
                .CFont(.headline02Regular)
                .foregroundStyle(.text03)
            Spacer()
            
            Button{
                print("편집")
            } label: {
                Text("편집")
                    .CFont(.body01Regular)
                    .foregroundStyle(isDisabled ? .gray03 : .text03)
            }
            .disabled(isDisabled)
        }
        .padding(.horizontal, 16)
        .padding(.top)
    }
    
    private var searchBar: some View {
        // 기본 검색 TextField
        HStack {
            TextField("추가할 태그를 입력해주세요", text: $searchTag,
                      prompt: Text("추가할 태그를 입력해주세요")
                .foregroundStyle(.text03)
            )
            .CFont(.body02Regular)
            .foregroundColor(.text02)
            .padding(.leading, 12)
            .padding(.trailing, 6)
            .padding(.vertical, 8)
            .cornerRadius(8)
            
            Button {
                print("cancel")
            } label: {
                Text("등록")
                    .CFont(.body02Regular)
                    .foregroundStyle(.text03)
            }
            .padding(.trailing, 12)
        }
        .cornerRadius(8)
        .background(Color.gray01)
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
    }
    
    private var noTagListView: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("등록된 태그가 없어요.")
                .CFont(.headline02Bold)
                .foregroundStyle(.text01)
            Text("태그로 분류하면 원하는 이미지를\n쉽게 찾을 수 있어요!")
                .CFont(.body01Regular)
                .multilineTextAlignment(.center)
                .foregroundStyle(.text03)
            Spacer()
        }
    }
    
    private var tagListView: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(tags, id: \.id) { tag in
                    TagRow(
                        tag: tag,
                        onEdit: { edit(tag) }
                    )
                    
                    // 인셋된 구분선 느낌 (왼쪽 여백 맞추기)
                    Divider()
                        .padding(.leading, 16)
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .padding(.horizontal, 0)
        }
    }
    
    private func edit(_ tag: Tag) {
        print("수정: \(tag.name)")
        self.tagEditBottomSheet = true
    }
}
