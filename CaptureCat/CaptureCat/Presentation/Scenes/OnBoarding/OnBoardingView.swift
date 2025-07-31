//
//  OnBoardingView.swift
//  CaptureCat
//
//  Created by minsong kim on 7/11/25.
//

import SwiftUI

struct OnBoardingView: View {
    @Binding var viewModel: OnBoardingViewModel
    
    var body: some View {
        VStack(spacing: 32) {
            HStack {
                Spacer()
                Button {
                    viewModel.skipOnBoarding()
                } label: {
                    Text("건너뛰기")
                        .CFont(.body02Regular)
                        .foregroundStyle(.text03)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 33)
            
            Image(viewModel.onBoardingPages[viewModel.currentPage].image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity)
            Text(viewModel.onBoardingPages[viewModel.currentPage].description)
                .CFont(.headline01Bold)
                .multilineTextAlignment(.center)
            Image(viewModel.onBoardingPages[viewModel.currentPage].indicator)
            Button(viewModel.onBoardingPages[viewModel.currentPage].next) {
                withAnimation {
                    viewModel.increasePage()
                }
            }
            .primaryStyle()
            .padding(.horizontal, 16)
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    let threshold: CGFloat = 30
                    
                    // 오른쪽에서 왼쪽으로 스와이프 (다음 페이지)
                    if value.translation.width < -threshold {
                        withAnimation {
                            viewModel.increasePage()
                        }
                    }
                    // 왼쪽에서 오른쪽으로 스와이프 (이전 페이지)
                    else if value.translation.width > threshold {
                        withAnimation {
                            viewModel.decreasePage()
                        }
                    }
                }
        )
    }
}
