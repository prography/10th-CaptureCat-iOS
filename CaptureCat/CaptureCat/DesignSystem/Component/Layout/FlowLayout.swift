//
//  FlowLayout.swift
//  CaptureCat
//
//  Created by minsong kim on 8/31/25.
//

import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize,
                      subviews: Subviews,
                      cache: inout ()) -> CGSize {
        layout(subviews: subviews, proposal: proposal).size
    }

    func placeSubviews(in bounds: CGRect,
                       proposal: ProposedViewSize,
                       subviews: Subviews,
                       cache: inout ()) {
        let result = layout(subviews: subviews, proposal: proposal)
        for (i, f) in result.frames.enumerated() {
            subviews[i].place(at: CGPoint(x: bounds.minX + f.origin.x,
                                          y: bounds.minY + f.origin.y),
                              proposal: ProposedViewSize(f.size))
        }
    }

    private func layout(subviews: Subviews,
                        proposal: ProposedViewSize) -> (size: CGSize, frames: [CGRect]) {
        let maxW = proposal.width ?? .greatestFiniteMagnitude

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0
        var frames: [CGRect] = []

        for v in subviews {
            // 각 버튼의 “자연 크기”(= 텍스트 길이 + 패딩 등)
            let sz = v.sizeThatFits(.unspecified)

            // 다음 아이템이 현재 줄에 안 들어가면 줄바꿈
            if x > 0, x + sz.width > maxW {
                x = 0
                y += rowH + rowSpacing
                rowH = 0
            }

            frames.append(CGRect(origin: CGPoint(x: x, y: y), size: sz))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }

        let usedW = min(maxW, frames.map(\.maxX).max() ?? 0)
        let usedH = (frames.last?.maxY ?? 0)
        return (CGSize(width: usedW, height: usedH), frames)
    }
}
