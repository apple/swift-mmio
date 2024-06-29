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

// NilCoalescingAssignment Operator
infix operator ??= : AssignmentPrecedence

extension Optional {
  /// Performs a nil-coalescing operation, replacing the wrapped value of with a
  /// default value if the wrapped value is nil.
  public static func ??= (
    lhs: inout Self,
    rhs: @autoclosure () -> Wrapped
  ) {
    lhs = lhs ?? rhs()
  }

  /// Performs a nil-coalescing operation, replacing the wrapped value of with
  /// an Optional default value if the wrapped value is nil.
  public static func ??= (
    lhs: inout Self,
    rhs: @autoclosure () -> Self
  ) {
    lhs = lhs ?? rhs()
  }
}
