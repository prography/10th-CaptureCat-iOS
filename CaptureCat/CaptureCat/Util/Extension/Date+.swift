//
//  Date+.swift
//  CaptureCat
//
//  Created by minsong kim on 7/22/25.
//

import Foundation

extension Date {
    func toString(format: String = "yyyy년 MM월 dd일") -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        return dateFormatter.string(from: self)
    }
}
