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
/// An object which can modify the behavior of register reads and writes for the
/// purpose of unit testing.
///
/// MMIOInterposers must provide methods for registers to load and store values.
/// However, conforming types may perform arbitrary logic within these methods.
/// For example, an interposer may adjust the address before performing a load
/// or store, it may load or store from a custom side allocation, or even simply
/// track load and store counts and discard the actual values.
public protocol MMIOInterposer: AnyObject {
  /// An interposition function to modify the behavior of a register read.
  ///
  /// - Returns: A `Value` from the address referenced by `pointer`.
  func load<Value>(
    from pointer: UnsafePointer<Value>
  ) -> Value where Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage

  /// An interposition function to modify the behavior of a register write.
  func store<Value>(
    _ value: Value,
    to pointer: UnsafeMutablePointer<Value>
  ) where Value: FixedWidthInteger & UnsignedInteger & _RegisterStorage
}
#endif
