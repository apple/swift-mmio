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

extension Parser2 {
  public static func binaryOrAnyDigit(
  ) -> some ParserProtocol<String.UTF8View.SubSequence, (UInt8, UInt8)> {
    BinaryOrAnyDigitParser2()
  }

  public static func binaryDigit(
  ) -> some ParserProtocol<String.UTF8View.SubSequence, UInt8> {
    BinaryDigitParser2()
  }

  public static func octalDigit(
  ) -> some ParserProtocol<String.UTF8View.SubSequence, UInt8> {
    OctalDigitParser2()
  }

  public static func decimalDigit(
  ) -> some ParserProtocol<String.UTF8View.SubSequence, UInt8> {
    DecimalDigitParser2()
  }

  public static func hexadecimalDigit(
  ) -> some ParserProtocol<String.UTF8View.SubSequence, UInt8> {
    HexadecimalDigitParser2()
  }
}

struct BinaryOrAnyDigitParser2: ParserProtocol {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = (UInt8, UInt8) // (Value, Mask)

  func parse(_ input: inout Input) -> Output? {
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

struct BinaryDigitParser2: ParserProtocol {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = UInt8

  func parse(_ input: inout Input) -> Output? {
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

struct OctalDigitParser2: ParserProtocol {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = UInt8

  func parse(_ input: inout Input) -> Output? {
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

struct DecimalDigitParser2: ParserProtocol {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = UInt8

  func parse(_ input: inout Input) -> Output? {
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

struct HexadecimalDigitParser2: ParserProtocol {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = UInt8

  func parse(_ input: inout Input) -> Output? {
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
