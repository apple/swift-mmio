//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public struct BinaryOrAnyDigitParser: ParserProtocol {
  public typealias Output = (UInt8, UInt8)  // (Value, Mask)

  public init() {}

  public func parse(_ input: inout Input) -> Output? {
    guard let ascii = input.first else { return nil }
    switch ascii {
    case UInt8(ascii: "0"), UInt8(ascii: "1"):
      _ = input.removeFirst()
      return (ascii - UInt8(ascii: "0"), 1)
    case UInt8(ascii: "x"), UInt8(ascii: "X"):
      _ = input.removeFirst()
      return (0, 0)
    default:
      return nil
    }
  }
}

public struct BinaryDigitParser: ParserProtocol {
  public typealias Output = UInt8

  public init() {}

  public func parse(_ input: inout Input) -> Output? {
    guard let ascii = input.first else { return nil }
    switch ascii {
    case UInt8(ascii: "0"), UInt8(ascii: "1"):
      _ = input.removeFirst()
      return ascii - UInt8(ascii: "0")
    default:
      return nil
    }
  }
}

public struct OctalDigitParser: ParserProtocol {
  public typealias Output = UInt8

  public init() {}

  public func parse(_ input: inout Input) -> Output? {
    guard let ascii = input.first else { return nil }
    switch ascii {
    case UInt8(ascii: "0")..<UInt8(ascii: "8"):
      _ = input.removeFirst()
      return ascii - UInt8(ascii: "0")
    default:
      return nil
    }
  }
}

public struct DecimalDigitParser: ParserProtocol {
  public typealias Output = UInt8

  public init() {}

  public func parse(_ input: inout Input) -> Output? {
    guard let ascii = input.first else { return nil }
    switch ascii {
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      _ = input.removeFirst()
      return ascii - UInt8(ascii: "0")
    default:
      return nil
    }
  }
}

public struct HexadecimalDigitParser: ParserProtocol {
  public typealias Output = UInt8

  public init() {}

  public func parse(_ input: inout Input) -> Output? {
    guard let ascii = input.first else { return nil }
    switch ascii {
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      _ = input.removeFirst()
      return ascii - UInt8(ascii: "0")
    case UInt8(ascii: "a")...UInt8(ascii: "f"):
      _ = input.removeFirst()
      return ascii - UInt8(ascii: "a") + 10
    case UInt8(ascii: "A")...UInt8(ascii: "F"):
      _ = input.removeFirst()
      return ascii - UInt8(ascii: "A") + 10
    default:
      return nil
    }
  }
}
