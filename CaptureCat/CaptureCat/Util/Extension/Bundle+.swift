//
//  Bundle+.swift
//  CaptureCat
//
//  Created by minsong kim on 7/17/25.
//

import Foundation

extension Bundle {
    var kakaoKey: String? {
        object(forInfoDictionaryKey: "KAKAO_API_KEY") as? String
    }
}
