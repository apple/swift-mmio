// The Swift Programming Language
// https://docs.swift.org/swift-book

struct BinaryOrAnyDigitParser2: Parser2 {
  typealias Input = String.UTF8View.SubSequence
  // (Value, Mask)
  typealias Output = (UInt8, UInt8)

  static func parse(_ input: inout Input) -> Output? {
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

struct BinaryDigitParser2: Parser2 {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = UInt8

  static func parse(_ input: inout Input) -> Output? {
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

struct OctalDigitParser2: Parser2 {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = UInt8

  static func parse(_ input: inout Input) -> Output? {
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

struct DecimalDigitParser2: Parser2 {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = UInt8

  static func parse(_ input: inout Input) -> Output? {
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

struct HexadecimalDigitParser2: Parser2 {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = UInt8

  static func parse(_ input: inout Input) -> Output? {
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
