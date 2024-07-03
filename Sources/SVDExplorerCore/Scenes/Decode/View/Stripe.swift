//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import CoreGraphics
import SwiftUI

struct DecoderStripedBackgroundView: ShapeStyle {
  var foregroundColor: Color
  var backgroundColor: Color
  var lineSpacing = 5.0
  var lineWidth = 2.0

  var body: some View {
    Canvas { context, size in
      for index in 0..<(Int(size.width) + 3) {
        var linePath = Path()
        let offset = size.height + 2 * lineWidth
        let point1 = CGPoint(x: Double(index) * lineSpacing - offset, y: offset)
        let point2 = CGPoint(x: Double(index) * lineSpacing, y: 0)
        linePath.move(to: point1)
        linePath.addLine(to: point2)
        context.stroke(
          linePath,
          with: .color(self.foregroundColor),
          lineWidth: CGFloat(lineWidth))
      }
    }
    .background(self.backgroundColor)
  }
}

//#Preview {
//  DecoderStripedBackgroundView(
//    foregroundColor: .blue.opacity(0.2),
//    backgroundColor: .yellow.opacity(0.2))
//}
