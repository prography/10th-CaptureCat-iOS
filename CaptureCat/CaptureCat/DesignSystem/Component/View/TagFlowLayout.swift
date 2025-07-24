//
//  TagFlowLayout.swift
//  CaptureCat
//
//  Created by Assistant on 1/21/25.
//

import SwiftUI

struct TagFlowLayout: View {
    let tags: [String]
    let maxLines: Int
    
    init(tags: [String], maxLines: Int = 2) {
        self.tags = tags
        self.maxLines = maxLines
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            let groupedTags = arrangeTagsInLines()
            
            ForEach(Array(groupedTags.enumerated()), id: \.offset) { lineIndex, lineTags in
                if lineIndex < maxLines {
                    HStack(spacing: 4) {
                        ForEach(lineTags, id: \.self) { tag in
                            Text(tag)
                                .CFont(.caption01Semibold)
                                .padding(.horizontal, 7.5)
                                .padding(.vertical, 4.5)
                                .background(Color.overlayDim)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
    }
    
    /// 태그들을 줄별로 배치하는 로직
    private func arrangeTagsInLines() -> [[String]] {
        var lines: [[String]] = []
        var currentLine: [String] = []
        var currentLineWidth: CGFloat = 0
        let maxWidth: CGFloat = 130 // 적절한 너비 제한 (아이템 뷰 크기 기준)
        
        for tag in tags {
            let tagWidth = estimateTagWidth(tag)
            
            // 현재 줄에 태그를 추가할 수 있는지 확인
            if currentLineWidth + tagWidth <= maxWidth && currentLine.count < 3 {
                currentLine.append(tag)
                currentLineWidth += tagWidth + 4 // 4는 spacing
            } else {
                // 새로운 줄 시작
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                }
                currentLine = [tag]
                currentLineWidth = tagWidth
            }
        }
        
        // 마지막 줄 추가
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }
        
        return lines
    }
    
    /// 태그의 예상 너비 계산
    private func estimateTagWidth(_ tag: String) -> CGFloat {
        // 대략적인 문자당 너비 + 패딩
        let characterWidth: CGFloat = 8
        let padding: CGFloat = 15 // horizontal padding 7.5 * 2
        return CGFloat(tag.count) * characterWidth + padding
    }
} 