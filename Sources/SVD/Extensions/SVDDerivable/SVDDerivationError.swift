//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import MMIOUtilities

enum SVDDerivationError: Error {
  case derivationFromUnknownNode(String, String, String, [String])
  case cyclicDerivation(String, [String])
}

extension SVDDerivationError: CustomStringConvertible {
  var description: String {
    switch self {
    case .derivationFromUnknownNode(
      let kind, let nodeName, let parentName, let options):
      """
      \(kind) '\(nodeName)' derived from unknown item \
      '\(parentName)', valid options: \(list: options).
      """
    case .cyclicDerivation(let kind, let cycle):
      """
      \(kind) '\(cycle[0])' has a cyclic dependency on itself, \
      cycle: \(cycle: cycle).
      """
    }
  }
}
