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

import SVD

extension String {
  func coalescingConsecutiveSpaces() -> Self {
    if #available(macOS 13.0, *) {
      self.replacing(#/  +/#, with: " ")
    } else {
      self.split(separator: " ").joined(separator: " ")
    }
  }

  func removingUnsafeCharacters() -> Self {
    self
      .replacingOccurrences(of: "%s", with: "")
      .replacingOccurrences(of: "[]", with: "")
      .replacingOccurrences(of: "-", with: "_")
      .replacingOccurrences(of: " ", with: "_")
  }
}
