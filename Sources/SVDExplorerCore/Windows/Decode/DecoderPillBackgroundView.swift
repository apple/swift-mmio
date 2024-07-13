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

import SwiftUI

func DecoderPillBackgroundView(
  radius: CGFloat,
  fill: Color,
  stroke: Color
) -> some View {
  RoundedRectangle(cornerRadius: radius, style: .continuous)
    .fill(fill)
    .stroke(stroke, lineWidth: 1)
}
