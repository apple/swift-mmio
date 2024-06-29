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

/// A structure representing an error that occurs when an Optional value is
/// unexpectedly found to be nil.
public struct OptionalUnwrappingError {
  /// The file in which the error occurred.
  var file: StaticString
  /// The line number at which the error occurred.
  var line: UInt

  /// Initializes a new instance of `OptionalUnwrappingError`.
  ///
  /// - Parameters:
  ///   - file: The file in which the error occurred.
  ///   - line: The line number at which the error occurred.
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
  #if swift(>=6)
  /// Unwraps an Optional value, throwing an error if the value is nil.
  ///
  /// - Parameters:
  ///   - file: The file in which the unwrapping occurs.
  ///   - line: The line number at which the unwrapping occurs.
  /// - Throws: An `OptionalUnwrappingError` if the value is nil.
  /// - Returns: The unwrapped value.
  public func unwrap(
    file: StaticString = #file,
    line: UInt = #line
  ) throws(OptionalUnwrappingError) -> Wrapped {
    guard let self = self else {
      throw OptionalUnwrappingError(file: file, line: line)
    }
    return self
  }

  /// Unwraps an Optional value, throwing a specified error if the value is nil.
  ///
  /// - Parameter error: The error to throw if the value is nil.
  /// - Throws: The specified error if the value is nil.
  /// - Returns: The unwrapped value.
  public func unwrap<E>(
    or error: E
  ) throws(E) -> Wrapped where E: Error {
    guard let self = self else { throw error }
    return self
  }
  #else
  /// Unwraps an Optional value, throwing an error if the value is nil.
  ///
  /// - Parameters:
  ///   - error: A custom error to throw if the value is nil.
  ///   - file: The file in which the unwrapping occurs.
  ///   - line: The line number at which the unwrapping occurs.
  /// - Throws: An error if value is nil.
  /// - Returns: The unwrapped value.
  public func unwrap(
    or error: (any Error)? = nil,
    file: StaticString = #file,
    line: UInt = #line
  ) throws -> Wrapped {
    guard let self = self else {
      throw error ?? OptionalUnwrappingError(file: file, line: line)
    }
    return self
  }
  #endif
}
