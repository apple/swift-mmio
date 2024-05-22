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

struct OptionalUnwrappingError {}

extension OptionalUnwrappingError: CustomStringConvertible {
  var description: String {
    "Unexpectedly found nil while unwrapping an Optional value"
  }
}

extension OptionalUnwrappingError: Error {}

extension Optional {
  func unwrap(or error: Error = OptionalUnwrappingError()) throws -> Wrapped {
    guard let self = self else { throw error }
    return self
  }
}
