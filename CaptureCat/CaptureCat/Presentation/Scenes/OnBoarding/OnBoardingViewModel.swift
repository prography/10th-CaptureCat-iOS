//
//  OnBoardingViewModel.swift
//  CaptureCat
//
//  Created by minsong kim on 7/16/25.
//

import SwiftUI

@Observable
class OnBoardingViewModel {
    var currentPage: Int = 0
    let onBoardingPages: [Page] =
    [Page(description: NSLocalizedString("스크린샷만 쏙\n골라서 저장해요", comment: "온보딩 첫 번째 페이지 설명"), image: .onBoard1, indicator: .indicator1, next: NSLocalizedString("다음", comment: "다음 버튼")),
         Page(description: NSLocalizedString("여러 장을 한 번에\n태그로 정리해요", comment: "온보딩 두 번째 페이지 설명"), image: .onBoard2, indicator: .indicator2, next: NSLocalizedString("다음", comment: "다음 버튼")),
         Page(description: NSLocalizedString("태그로 쉽게 찾고\n바로 활용해요", comment: "온보딩 세 번째 페이지 설명"), image: .onBoard3, indicator: .indicator3, next: NSLocalizedString("시작하기", comment: "시작하기 버튼"))]
    var isOnBoarding: Bool = true
    
    init() {
        if KeyChainModule.read(key: .didOnboarding) == "true" {
            self.isOnBoarding = false
        }
    }
    
    func increasePage() {
        if currentPage < onBoardingPages.count - 1 {
            currentPage += 1
        } else {
            isOnBoarding = false
            KeyChainModule.create(key: .didOnboarding, data: "true")
        }
    }

    func decreasePage() {
        if currentPage > 0 {
            currentPage -= 1
        }
    }
    
    func skipOnBoarding() {
        isOnBoarding = false
        KeyChainModule.create(key: .didOnboarding, data: "true")
    }
}

struct Page {
    let description: String
    let image: ImageResource
    let indicator: ImageResource
    let next: String
}
