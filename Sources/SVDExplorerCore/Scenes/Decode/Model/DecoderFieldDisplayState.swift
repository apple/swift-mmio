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
  var caseName: CaseName

  enum CaseName: Hashable {
    case unknown
    case invalid
    case valid(String)
  }
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
    switch (self.focus, self.caseName) {
    case (true, .invalid): .purple
    case (true, .valid): .blue
    case (true, .unknown): .green
    case (false, .invalid): .red
    case (false, .valid): .gray
    case (false, .unknown): .yellow
    }
  }
}
