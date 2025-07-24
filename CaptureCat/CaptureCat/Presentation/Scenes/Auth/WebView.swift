//
//  WebView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/24/25.
//

enum WebLink {
    case terms
    case personal
    
    var url: String {
        switch self {
        case .terms:
            return "https://ujins.notion.site/1ff6b91b83f580519258d2256a319737?source=copy_link"
        case .personal:
            return "https://ujins.notion.site/1ff6b91b83f58081abb1e90909cce9fd?source=copy_link"
        }
    }
}

import SwiftUI

struct WebView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    var webLink: WebLink
    
    var body: some View {
        VStack {
            CustomNavigationBar(title: "", onBack: {
                viewModel.authenticationState = .initial
            })
            WKWebViewPresentation(url: webLink.url)
        }
    }
}
