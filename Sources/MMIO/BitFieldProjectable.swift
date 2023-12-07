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

public protocol BitFieldProjectable {
  static var bitWidth: Int { get }

  init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger

  func storage<Storage>(_: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger
}

extension Never: BitFieldProjectable {
  public static var bitWidth: Int { fatalError() }

  public init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger { fatalError() }

  public func storage<Storage>(_: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger { fatalError() }
}

extension Bool: BitFieldProjectable {
  public static let bitWidth = 1

  public init<Storage>(storage: Storage)
  where Storage: FixedWidthInteger & UnsignedInteger {
    self = storage != 0b0
  }

  public func storage<Storage>(_: Storage.Type) -> Storage
  where Storage: FixedWidthInteger & UnsignedInteger {
    self ? 0b1 : 0b0
  }
}

extension RawRepresentable where Self: BitFieldProjectable, RawValue: FixedWidthInteger {
  public init<Storage>(storage: Storage) where Storage: FixedWidthInteger & UnsignedInteger {
      self.init(rawValue: RawValue(storage))!
  }

  public func storage<Storage>(_: Storage.Type) -> Storage where Storage: FixedWidthInteger & UnsignedInteger {
    Storage(rawValue)
  }
}

@inline(__always)
public func preconditionMatchingBitWidth(
  _ fieldType: (some BitField).Type,
  _ projectedType: (some BitFieldProjectable).Type,
  file: StaticString = #file,
  line: UInt = #line
) {
  #if hasFeature(Embedded)
  // FIXME: Embedded doesn't have static interpolated strings yet
  precondition(
    fieldType.bitWidth == projectedType.bitWidth,
    "Illegal projection of bit-field as type of differing bit-width",
    file: file,
    line: line)
  #else
  precondition(
    fieldType.bitWidth == projectedType.bitWidth,
    """
    Illegal projection of \(fieldType.bitWidth) bit bit-field '\(fieldType)' \
    as \(projectedType.bitWidth) bit type '\(projectedType)'
    """,
    file: file,
    line: line)
  #endif
}
