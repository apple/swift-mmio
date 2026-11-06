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

import SVD

struct SVDDimRegisterMatch {
  let register: SVDRegister
  let index: UInt64
}

extension StringProtocol {
  /// Match a key like `GPIO[0]` against an SVD register name like `GPIO%s`.
  func matchesDimRegister(_ registerName: String) -> UInt64? {
    let query = String(self)
    guard let open = query.firstIndex(of: "["), let close = query.firstIndex(of: "]"),
          close > open else {
      return nil
    }
    let base = String(query[..<open])
    let indexString = String(query[query.index(after: open)..<close])
    guard let index = UInt64(indexString) else { return nil }
    let pattern = registerName.replacingOccurrences(of: "%s", with: "")
    if base.matches(pattern) || base.matches(registerName) {
      return index
    }
    return nil
  }
}

extension SVDRegister {
  func dimIndex(for name: some StringProtocol) -> UInt64? {
    guard let dimensionElement = self.dimensionElement else { return nil }
    guard let index = name.matchesDimRegister(self.name) else { return nil }
    guard index < dimensionElement.dim else { return nil }
    return index
  }

  func address(forDimIndex index: UInt64, baseAddress: UInt64) -> UInt64? {
    guard let dimensionElement = self.dimensionElement else { return nil }
    guard index < dimensionElement.dim else { return nil }
    return baseAddress + (dimensionElement.dimIncrement * index)
  }
}
