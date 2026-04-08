//
//  PoseOverlayView.swift
//  VisionDraft
//
//  Created by Eyhciurmrn Zmpodackrl on 07.04.2026.
//

import SwiftUI

struct PoseOverlayView: View {
  let points: [CGPoint]
  let size: CGSize
  
  var body: some View {
    Canvas { context, size in
      for point in points {
        let x = point.x * size.width
        let y = point.y * size.height
        
        let dotRadius: CGFloat = 4
        let dot = Path(ellipseIn: CGRect(x: x - dotRadius, y: y - dotRadius, width: dotRadius * 2, height: dotRadius * 2))
        context.fill(dot, with: .color(.red))
      }
    }
  }
}
