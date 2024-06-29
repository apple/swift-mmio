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

extension MutableCollection {
  #if swift(>=6)
  /// Iterate through a collection mutating each element.
  ///
  /// This is a workaround for Swift not having first class support for:
  /// ```swift
  /// for mutating element in collection
  /// ```
  ///
  /// - Parameter body: Mutating operation to perform on each element.
  /// - Throws: Re-throws errors thrown by `body`.
  public mutating func mutatingForEach<E>(
    body: (inout Self.Element) throws(E) -> Void
  ) throws(E) where E: Error {
    var currentIndex = self.startIndex
    while currentIndex != self.endIndex {
      try body(&self[currentIndex])
      self.formIndex(after: &currentIndex)
    }
  }
  #else
  /// Iterate through a collection mutating each element.
  ///
  /// This is a workaround for Swift not having first class support for:
  /// ```swift
  /// for mutating element in collection
  /// ```
  ///
  /// - Parameter body: Mutating operation to perform on each element.
  /// - Throws: Re-throws errors thrown by `body`.
  public mutating func mutatingForEach(
    body: (inout Self.Element) throws -> Void
  ) rethrows {
    var currentIndex = self.startIndex
    while currentIndex != self.endIndex {
      try body(&self[currentIndex])
      self.formIndex(after: &currentIndex)
    }
  }
  #endif
}
