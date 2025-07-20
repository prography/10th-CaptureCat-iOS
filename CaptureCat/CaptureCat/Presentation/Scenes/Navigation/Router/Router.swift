//
//  Router.swift
//  CaptureCat
//
//  Created by minsong kim on 7/6/25.
//

import SwiftUI
import Photos

final class Router: ObservableObject {
    enum Route: Hashable {
        case tag(ids: [String])
        case setting
    }

    @Published var path = NavigationPath()
    
    func push(_ route: Route) {
        path.append(route)
    }
    
    func pop() {
        path.removeLast()
    }
    
    func popToRoot() {
        path.removeLast(path.count)
    }
}
