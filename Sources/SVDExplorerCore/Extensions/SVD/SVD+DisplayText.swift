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

extension SVDWriteConstraint {
  var displayText: String {
    switch self {
    case .writeAsRead(let bool):
      if bool.writeAsRead {
        "Last Value Read"
      } else {
        "No Constraint"
      }
    case .useEnumeratedValues(let bool):
      if bool {
        "Use Predefined Values"
      } else {
        "No Constraint"
      }
    case .range(let range):
      "Any Value in \(range.minimum)...\(range.maximum)"
    }
  }
}

extension SVDModifiedWriteValues {
  var displayText: String {
    switch self {
    case .oneToClear: "One To Clear"
    case .oneToSet: "One To Set"
    case .oneToToggle: "One To Toggle"
    case .zeroToClear: "Zero To Clear"
    case .zeroToSet: "Zero To Set"
    case .zeroToToggle: "Zero to Toggle"
    case .clear: "Clear"
    case .set: "Set"
    // FIXME: unclear
    // if this means the value written is stored as is or has arbitrary
    // modifications
    case .modify: "Modify"
    }
  }
}
