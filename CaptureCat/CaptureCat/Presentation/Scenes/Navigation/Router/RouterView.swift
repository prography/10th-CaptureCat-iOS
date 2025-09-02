//
//  RouterView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/6/25.
//

import SwiftUI

struct RouterView<Content: View>: View {
    @StateObject var router: Router = Router()
    @EnvironmentObject var repository: ScreenshotRepository
    
    private let content: Content
    private let networkManager: NetworkManager
    
    init(networkManager: NetworkManager,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.networkManager = networkManager
        self.content = content()
    }
    
    var body: some View {
        NavigationStack(path: $router.path) {
            content
                .navigationDestination(for: Router.Route.self) { route in
                    switch route {
                    case .startGetScreenshot:
                        let viewModel = StartGetScreenshotViewModel(repository: repository, service: TutorialService(networkManager: networkManager))
                        StartGetScreenshotView(viewModel: viewModel)
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    case .permission:
                        PermissionView()
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    case .tag(let ids):
                        let viewModel = TagViewModel(itemsIds: ids, repository: repository, router: router)
                        TagView(viewModel: viewModel)
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    case .setting:
                        SettingsView()
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    case .favorite:
                        let viewModel = FavoriteViewModel(repository: repository)
                        FavoriteView(viewModel: viewModel)
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    case .detail(let id):
                        let viewModel = DetailViewModel(imageId: id, repository: repository)
                        DetailView(viewModel: viewModel, imageId: id)
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    case .completeSave(let count):
                        UploadCompleteView(count: count)
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    case .completeSync(let result):
                        SyncCompletedView(syncResult: result)
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    case .withdraw:
                        WithdrawView()
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    case .tagSetting:
                        TagSettingView()
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    case .recommendLogIn:
                        RecommandLoginView()
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    case .searchResult:
                        SearchResultView()
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                }
        }
        .environmentObject(router)
    }
}
