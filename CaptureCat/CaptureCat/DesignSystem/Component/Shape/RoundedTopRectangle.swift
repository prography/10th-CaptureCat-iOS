//
//  RoundedTopRectangle.swift
//  CaptureCat
//
//  Created by minsong kim on 10/23/25.
//

import SwiftUI

struct RoundedTopRectangle: Shape {
    var cornerRadius: CGFloat = 4
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let radius = min(cornerRadius, rect.width/2, rect.height/2)
        
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + radius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + radius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}
