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

/// A container type referencing of a region of memory whose layout is defined
/// by another type.
public struct RegisterArray<Value> where Value: RegisterValue {
  public var unsafeAddress: UInt
  public var stride: UInt
  public var count: UInt

  #if FEATURE_INTERPOSABLE
  public var interposer: (any MMIOInterposer)?
  #endif

  @inlinable @inline(__always)
  static func preconditionAligned(unsafeAddress: UInt, stride: UInt) {
    let alignment = MemoryLayout<Value.Raw.Storage>.alignment
    #if $Embedded
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      unsafeAddress.isMultiple(of: UInt(alignment)),
      "Misaligned address")
    precondition(
      stride.isMultiple(of: UInt(alignment)),
      "Misaligned stride")
    #else
    precondition(
      unsafeAddress.isMultiple(of: UInt(alignment)),
      "Misaligned address '\(unsafeAddress)' for data of type '\(Value.self)'")
    precondition(
      stride.isMultiple(of: UInt(alignment)),
      "Misaligned stride '\(unsafeAddress)' for data of type '\(Value.self)'")
    #endif
  }

  #if FEATURE_INTERPOSABLE
  @inlinable @inline(__always)
  public init(
    unsafeAddress: UInt,
    stride: UInt,
    count: UInt,
    interposer: (any MMIOInterposer)?
  ) {
    Self.preconditionAligned(unsafeAddress: unsafeAddress, stride: stride)
    self.unsafeAddress = unsafeAddress
    self.stride = stride
    self.count = count
    self.interposer = interposer
  }
  #else
  @inlinable @inline(__always)
  public init(
    unsafeAddress: UInt,
    stride: UInt,
    count: UInt
  ) {
    Self.preconditionAligned(unsafeAddress: unsafeAddress, stride: stride)
    self.unsafeAddress = unsafeAddress
    self.stride = stride
    self.count = count
  }
  #endif
}

extension RegisterArray {
  @inlinable @inline(__always)
  subscript<Index>(
    _ index: Index
  ) -> Register<Value> where Index: BinaryInteger {
    #if $Embedded
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      0 <= index && index < self.count,
      "Index out of bounds")
    #else
    precondition(
      0 <= index && index < self.count,
      "Index '\(index)' out of bounds '0..<\(self.count)'")
    #endif
    let index = UInt(index)
    #if FEATURE_INTERPOSABLE
    return .init(
      unsafeAddress: self.unsafeAddress + (index * self.stride),
      interposer: self.interposer)
    #else
    return .init(unsafeAddress: self.unsafeAddress + (index * self.stride))
    #endif
  }
}
