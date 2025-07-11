//
//  RouterView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/6/25.
//

import SwiftUI

struct RouterView<Content: View>: View {
    @StateObject var router: Router = Router()
    
    private let content: Content
    
    init(
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.content = content()
    }
    
    var body: some View {
        NavigationStack(path: $router.path) {
            content
                .navigationDestination(for: Router.Route.self) { route in
                    switch route {
                    case .tag(let assets):
                        TagView(assets: assets)
                            .navigationBarBackButtonHidden()
                            .toolbar(.hidden, for: .navigationBar)
                    }
                }
        }
        .environmentObject(router)
    }
}
