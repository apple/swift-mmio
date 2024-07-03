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

public import Foundation
import MMIOUtilities

struct SVDDecodingError: Error, CustomStringConvertible {
  var description: String
}

extension SVDDevice {
  public init(data: Data) throws {
    let root = try XMLElementBuilder.build(data: data)
      .unwrap(or: SVDDecodingError(description: "Missing root XML element"))
    try self.init(root.wrapped)
  }

  package init() {
    self.init(
      name: "Fake",
      addressUnitBits: 0,
      width: 0,
      peripherals: .init(peripheral: []))
  }
}
