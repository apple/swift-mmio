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
public struct Register<Value> where Value: RegisterValue {
  public var unsafeAddress: UInt

  #if FEATURE_INTERPOSABLE
  public var interposer: (any MMIOInterposer)?
  #endif

  @inlinable @inline(__always)
  static func preconditionAligned(unsafeAddress: UInt) {
    let alignment = MemoryLayout<Value.Raw.Storage>.alignment
    #if $Embedded
    // FIXME: Embedded doesn't have static interpolated strings yet
    precondition(
      unsafeAddress.isMultiple(of: UInt(alignment)),
      "Misaligned address")
    #else
    precondition(
      unsafeAddress.isMultiple(of: UInt(alignment)),
      "Misaligned address '\(unsafeAddress)' for data of type '\(Value.self)'")
    #endif
  }

  #if FEATURE_INTERPOSABLE
  @inlinable @inline(__always)
  public init(unsafeAddress: UInt, interposer: (any MMIOInterposer)?) {
    Self.preconditionAligned(unsafeAddress: unsafeAddress)
    self.unsafeAddress = unsafeAddress
    self.interposer = interposer
  }
  #else
  @inlinable @inline(__always)
  public init(unsafeAddress: UInt) {
    Self.preconditionAligned(unsafeAddress: unsafeAddress)
    self.unsafeAddress = unsafeAddress
  }
  #endif
}

extension Register {
  @inlinable @inline(__always)
  var pointer: UnsafeMutablePointer<Value.Raw.Storage> {
    .init(bitPattern: self.unsafeAddress).unsafelyUnwrapped
  }

  @inlinable @inline(__always)
  public func read() -> Value.Read {
    let storage: Value.Raw.Storage
    #if FEATURE_INTERPOSABLE
    if let interposer = self.interposer {
      storage = interposer.load(from: self.pointer)
    } else {
      storage = Value.Raw.Storage.load(from: self.pointer)
    }
    #else
    storage = Value.Raw.Storage.load(from: self.pointer)
    #endif
    return Value.Read(Value.Raw(storage))
  }

  @inlinable @inline(__always)
  public func write(_ newValue: Value.Write) {
    let storage = Value.Raw(newValue).storage
    #if FEATURE_INTERPOSABLE
    if let interposer = self.interposer {
      interposer.store(storage, to: self.pointer)
    } else {
      Value.Raw.Storage.store(storage, to: self.pointer)
    }
    #else
    Value.Raw.Storage.store(storage, to: self.pointer)
    #endif
  }

  @inlinable @inline(__always)
  public func write<T>(_ body: (inout Value.Write) -> (T)) -> T {
    var newValue = Value.Write(Value.Raw(0))
    let returnValue = body(&newValue)
    self.write(newValue)
    return returnValue
  }

  @inlinable @inline(__always) @_disfavoredOverload
  public func modify<T>(_ body: (Value.Read, inout Value.Write) -> (T)) -> T {
    let value = self.read()
    var newValue = Value.Write(value)
    let returnValue = body(value, &newValue)
    self.write(newValue)
    return returnValue
  }
}

extension Register where Value.Read == Value.Write {
  // FIXME: Hide overload/base from code completion
  // blocked-by: rdar://116586222 (Hide overload+base method if overload is
  //   marked as deprecated in protocol specialization)
  //
  // swift-format-ignore
  @available(
    *,
    deprecated,
    message: """
      API misuse; symmetric registers have identical read and write views, use \
      modify method with single parameter closure instead. e.g. \
      'modify { rw in ... }'.
      """)
  @inlinable @inline(__always) @_disfavoredOverload
  public func modify<T>(_ body: (Value.Read, inout Value.Write) -> (T)) -> T {
    var value = self.read()
    let returnValue = body(value, &value)
    self.write(value)
    return returnValue
  }

  @inlinable @inline(__always)
  public func modify<T>(_ body: (inout Value.Write) -> (T)) -> T {
    var value = self.read()
    let returnValue = body(&value)
    self.write(value)
    return returnValue
  }
}
