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

public struct OptionalUnwrappingError {
  var file: StaticString
  var line: UInt

  init(file: StaticString = #file, line: UInt = #line) {
    self.file = file
    self.line = line
  }
}

extension OptionalUnwrappingError: CustomStringConvertible {
  public var description: String {
    """
    Unexpectedly found nil while unwrapping an Optional value at \
    \(self.file):\(self.line)
    """
  }
}

extension OptionalUnwrappingError: Error {}

extension Optional {
  public func unwrap(
    file: StaticString = #file,
    line: UInt = #line
  ) throws(OptionalUnwrappingError) -> Wrapped {
    guard let self = self else {
      throw OptionalUnwrappingError(file: file, line: line)
    }
    return self
  }

  public func unwrap<E>(
    or error: E
  ) throws(E) -> Wrapped where E: Error {
    guard let self = self else { throw error }
    return self
  }
}
