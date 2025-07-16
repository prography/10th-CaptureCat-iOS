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
    }
}
