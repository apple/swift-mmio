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

public typealias BitFieldStorage = FixedWidthInteger & UnsignedInteger

public protocol BitField<RawStorage> {
  associatedtype RawStorage: BitFieldStorage
  // var _rawStorage: RawStorage { get set }
  // init(_ _rawStorage: RawStorage)
  static var bitRange: Range<Int> { get }
  static var bitWidth: Int { get }
  static var bitOffset: Int { get }
  static var bitMask: RawStorage { get }
}

extension BitField {
  public static var bitWidth: Int { self.bitRange.count }
  public static var bitOffset: Int { self.bitRange.lowerBound }
  public static var bitMask: RawStorage { (1 << self.bitWidth) - 1 }
}

protocol ReadWriteBitField {

}
