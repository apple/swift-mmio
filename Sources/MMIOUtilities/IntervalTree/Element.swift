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

/// An element contained in an node of an interval tree.
///
/// Each element contains the range it encompasses and a value associated with
/// the range.
public struct Element<Bound, Value> where Bound: Comparable {
  /// The range associated with this element.
  public var range: Range<Bound>
  /// The value associated with this element.
  public var value: Value

  public init(range: Range<Bound>, value: Value) {
    self.range = range
    self.value = value
  }
}
