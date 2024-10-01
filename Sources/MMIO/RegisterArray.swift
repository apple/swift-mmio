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
public struct RegisterArray<Value> {
  public var unsafeAddress: UInt
  public var stride: UInt
  public var count: UInt

  #if FEATURE_INTERPOSABLE
  public var interposer: (any MMIOInterposer)?
  #endif

  #if FEATURE_INTERPOSABLE
  @inlinable @inline(__always)
  public init(
    unsafeAddress: UInt,
    stride: UInt,
    count: UInt,
    interposer: (any MMIOInterposer)?
  ) {
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
    self.unsafeAddress = unsafeAddress
    self.stride = stride
    self.count = count
  }
  #endif
}

extension RegisterArray where Value: RegisterValue {
  @inlinable @inline(__always)
  public subscript<Index>(
    _ index: Index
  ) -> Register<Value> where Index: BinaryInteger {
    #if hasFeature(Embedded)
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

extension RegisterArray where Value: RegisterProtocol {
  @inlinable @inline(__always)
  public subscript<Index>(
    _ index: Index
  ) -> Value where Index: BinaryInteger {
    #if hasFeature(Embedded)
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
