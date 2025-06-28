//
//  Array+.swift
//  CaptureCat
//
//  Created by minsong kim on 6/28/25.
//

import Foundation

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map { start in
            Array(self[start..<Swift.min(start + size, count)])
        }
    }
}
