//
//  ScreenshotItem.swift
//  CaptureCat
//
//  Created by minsong kim on 7/19/25.
//

import Foundation

struct ScreenshotItem: Identifiable {
    let id = UUID()
    let imageData: Data
    let createDate: String
    var tags: [String]
}
