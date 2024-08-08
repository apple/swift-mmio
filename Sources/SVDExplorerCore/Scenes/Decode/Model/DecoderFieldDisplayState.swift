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

struct DecoderFieldDisplayState {
  var focus: Bool
  var hover: Bool
  var invalid: Bool
}

extension DecoderFieldDisplayState {
  var fill: HierarchicalShapeStyle {
    self.hover ? .secondary : .tertiary
  }

  var strokeBorder: HierarchicalShapeStyle {
    self.hover ? .primary : .secondary
  }

  var foregroundStyle: Color {
    self.color
  }

  private var color: Color {
    switch (self.focus, self.invalid) {
    case (true, true): .purple
    case (true, false): .blue
    case (false, true): .red
    case (false, false): .gray
    }
  }
}
