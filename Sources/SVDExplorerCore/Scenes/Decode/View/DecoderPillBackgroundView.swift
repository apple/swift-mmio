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
  cornerRadius: CGFloat,
  displayState: DisplayState
) -> some View {
  RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
    .fill(displayState.fill)
    .stroke(displayState.stroke, lineWidth: 1)
}
