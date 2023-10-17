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

#if FEATURE_INTERPOSABLE
public protocol MMIOInterposer: AnyObject {
  // FIXME: Documentation is wrong
  /// Loads an instance of `value` from the address pointed to by pointer.
  func load<Value>(
    from pointer: UnsafePointer<Value>
  ) -> Value where Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage

  /// Stores an instance of `value` to the address pointed to by pointer.
  func store<Value>(
    _ value: Value,
    to pointer: UnsafeMutablePointer<Value>
  ) where Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage
}
#endif
