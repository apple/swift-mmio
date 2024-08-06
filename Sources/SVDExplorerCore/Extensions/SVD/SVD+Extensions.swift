//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import SVD

extension SVDAccess {
  var displayText: String {
    switch self {
    case .readOnly:
      "Read Only"
    case .writeOnly:
      "Write Only"
    case .readWrite:
      "Read Write"
    case .writeOnce:
      "Write Once"
    case .readWriteOnce:
      "Read Write Once"
    }
  }
}

extension SVDField {
  var accessDisplayText: String {
    self.access?.displayText ?? "Unknown"
  }
}
