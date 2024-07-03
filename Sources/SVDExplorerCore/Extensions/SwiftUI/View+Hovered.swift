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

extension View {
  func hovered(_ binding: Binding<Bool>) -> some View {
    self.onHover { binding.wrappedValue = $0 }
  }

  func hovered<Value>(_ binding: Binding<Value?>, equals value: Value)
    -> some View
  {
    self.onHover { binding.wrappedValue = $0 ? value : nil }
  }
}
