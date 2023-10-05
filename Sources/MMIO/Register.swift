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
public struct Register<Layout> where Layout: RegisterLayout {
  public private(set) var unsafeAddress: UInt
  var unsafePointer: UnsafeMutableRawPointer {
    let intValue = Int(bitPattern: self.unsafeAddress)
    return .init(bitPattern: intValue).unsafelyUnwrapped
  }

  @inline(__always)
  public init(unsafeAddress: UInt) {
    precondition(
      unsafeAddress.isMultiple(
        of: UInt(MemoryLayout<Layout.Read.MMIOVolatileRepresentation>.alignment)),
      "Misaligned address for data of type '\(Layout.self)'")
    self.unsafeAddress = unsafeAddress
  }
}

extension Register {
  @inline(__always)
  public func read() -> Layout.Read {
    self.unsafePointer.withMemoryRebound(to: Layout.Read.self, capacity: 1) {
      Layout.Read.load(from: $0)
    }
  }

  @inline(__always)
  public func write(_ newValue: Layout.Write) {
    self.unsafePointer.withMemoryRebound(to: Layout.Write.self, capacity: 1) {
      Layout.Write.store(newValue, to: $0)
    }
  }

  @inline(__always) @_disfavoredOverload
  public func modify<T>(_ body: (Layout.Read, inout Layout.Write) -> (T)) -> T {
    let value = self.read()
    var newValue = Layout.Write(value)
    let returnValue = body(value, &newValue)
    self.write(newValue)
    return returnValue
  }
}

extension Register where Layout.Read == Layout.Write {
  // TODO: New feature request to make overload unavailable
  // swift-format-ignore
  @available(
    *,
    deprecated,
    message: """
      API misuse; symmetric registers have identical read and write views, use \
      modify method with single parameter closure instead. e.g. \
      'modify { rw in ... }'.
      """)
  @inline(__always) @_disfavoredOverload
  public func modify<T>(_ body: (Layout.Read, inout Layout.Write) -> (T)) -> T {
    var value = self.read()
    let returnValue = body(value, &value)
    self.write(value)
    return returnValue
  }

  @inline(__always)
  public func modify<T>(_ body: (inout Layout.Write) -> (T)) -> T {
    var value = self.read()
    let returnValue = body(&value)
    self.write(value)
    return returnValue
  }
}
