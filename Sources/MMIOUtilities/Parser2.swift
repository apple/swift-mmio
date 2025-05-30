// The Swift Programming Language
// https://docs.swift.org/swift-book

public protocol Parser2<Input, Output> {
  associatedtype Input
  associatedtype Output

  static func parse(_ input: inout Input) -> Output?
}

extension Parser2 where Input == String.UTF8View.SubSequence {
  public static func parser() -> Parser<Substring, Output> {
    Parser<Substring, Output> { input in
      Self.parse(&input.utf8)
    }
  }
}


struct BaseParser2<Input>: Parser2 {
  typealias Output = Void
  static func parse(_ input: inout Input) -> Output? { () }
}

extension Parser2 where Output == Void {
  static func take<P: Parser2>(_ p: P) -> (some Parser2<Input, P.Output>).Type
  where P.Input == Input { Take1<Self, P>.self }
}


struct Take1<P0, P1>: Parser2
where P0: Parser2, P1: Parser2, P0.Input == P1.Input {
  typealias Input = P0.Input
  typealias Output = P1.Output

  static func parse(_ input: inout Input) -> Output? {
    let original = input
    if let _ = P0.parse(&input), let o1 = P1.parse(&input) {
      return o1
    } else {
      input = original
      return nil
    }
  }
}

extension Parser2 {
  func take<P: Parser2>(_ p: P) -> some Parser2<Input, (Output, P.Output)>
  where P.Input == Input { Take01(self, p) }
}

struct Take01<P0, P1>: Parser2
where P0: Parser2, P1: Parser2, P0.Input == P1.Input {
  typealias Input = P0.Input
  typealias Output = (P0.Output, P1.Output)

  var p0: P0
  var p1: P1

  init(_ p0: P0, _ p1: P1) {
    self.p0 = p0
    self.p1 = p1
  }

  static func parse(_ input: inout Input) -> Output? {
    let original = input
    if let o0 = P0.parse(&input), let o1 = P1.parse(&input) {
      return (o0, o1)
    } else {
      input = original
      return nil
    }
  }
}


// MARK: - Strings

extension Parser2 where Input == String.UTF8View.SubSequence {
  public static func parseAll(_ input: String) -> Output? {
    var input = input.utf8[...]
    guard let output = Self.parse(&input), input.isEmpty else { return nil }
    return output
  }

//  static func parseAll(_ input: inout Input) -> Output? {
//    let original = input
//    if let output = Self.parse(&input), input.isEmpty {
//      return output
//    }
//    else {
//      input = original
//      return nil
//    }
//  }
}

// MARK: - Numbers

protocol DigitParser2: Parser2<String.UTF8View.SubSequence, UInt8> {
  static var base: Int { get }
  static var prefix: String { get }
}

struct BinaryDigitParser2: DigitParser2 {
  static let base = 2
  static let prefix = "0b"

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

struct OctalDigitParser2: DigitParser2 {
  static let base = 8
  static let prefix = "0o"

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

struct DecimalDigitParser2: DigitParser2 {
  static let base = 10
  static let prefix = ""

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

struct HexadecimalDigitParser2: DigitParser2 {
  static let base = 16
  static let prefix = "0x"

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

struct LLVMDiagnosticInteger: Parser2 {
  typealias Input = String.UTF8View.SubSequence
  typealias Output = Int

  static func parse(_ input: inout Input) -> Output? {
    let digitParser2 = DecimalDigitParser2.self
    var match = 0
    var parsed = false
    while !input.isEmpty {
      guard
        let digit = digitParser2.parse(&input),
        match.incrementalParseAppend(digit: Int(digit), base: 10)
      else { break }
      parsed = true
    }
    guard parsed else { return nil }
    return match
  }
}

extension String.UTF8View.SubSequence: @retroactive Equatable {
  static public func == (lhs: Self, rhs: Self) -> Bool {
    guard lhs.count == rhs.count else { return false }
    return zip(lhs, rhs).allSatisfy(==)
  }
}

public struct SwiftIntegerParser2<Output>: Parser2 where Output: FixedWidthInteger {
  public typealias Input = String.UTF8View.SubSequence

  public static func parse(_ input: inout Input) -> Output? {
    let original = input

    var positive = true
    switch input.first {
    case UInt8(ascii: "-"):
      positive = false
      input.removeFirst()
    case UInt8(ascii: "+"):
      positive = true
      input.removeFirst()
    default:
      break
    }

    let digitParser2: any DigitParser2.Type
    switch input.prefix(2) {
    case BinaryDigitParser2.prefix.utf8[...]:
      digitParser2 = BinaryDigitParser2.self
      input.removeFirst(2)
    case OctalDigitParser2.prefix.utf8[...]:
      digitParser2 = OctalDigitParser2.self
      input.removeFirst(2)
    case HexadecimalDigitParser2.prefix.utf8[...]:
      digitParser2 = HexadecimalDigitParser2.self
      input.removeFirst(2)
    default:
      digitParser2 = DecimalDigitParser2.self
    }

    var value = Output(0)
    var digitsConsumed = false
    loop: while !input.isEmpty {
      // Attempt to parse a digit.
      guard let digit = digitParser2.parse(&input) else { break loop }

      // Add the digit to the parsed value.
      guard value.incrementalParseAppend(
        digit: SwiftIntegerParser2.Output(digit),
        base: SwiftIntegerParser2.Output(digitParser2.base))
      else {
        // Exit early on overflow.
        input = original
        return nil
      }

      digitsConsumed = true
      while input.first == UInt8(ascii: "_") {
        _ = input.removeFirst()
      }
    }

    guard digitsConsumed else {
      input = original
      return nil
    }

    return positive ? value : 0 - value
  }
}

//protocol OneOfParsable<Input> {
//  associatedtype Input
//  static var needle: Input { get }
//}
//
//struct OneOfParser2<Input, Output>: Parser2
//where Output: CaseIterable, Output: OneOfParsable, Output.Input == Input {
//  static func parse(_ input: inout Input) -> Output? {
//    for `case` in Output.allCases {
//      let prefix = `case`.needle[...]
//      if input.starts(with: prefix) {
//        input.removeFirst(prefix.count)
//        return `case`
//      }
//    }
//    return nil
//  }
//}

//public static func cases(_: Output.Type = Output.self) -> Self
//where Output: CaseIterable & RawRepresentable, Output.RawValue == String {
//  Self { input in
//    for `case` in Output.allCases {
//      let prefix = `case`.rawValue[...]
//      if input.starts(with: prefix) {
//        input.removeFirst(prefix.count)
//        return `case`
//      }
//    }
//    return nil
//  }
//}
//
//





extension FixedWidthInteger {
  mutating func incrementalParseAppend(
    digit: Self,
    base: Self
  ) -> Bool {
    let multiply = self.multipliedReportingOverflow(by: base)
    guard !multiply.overflow else { return false }
    let add = multiply.partialValue.addingReportingOverflow(digit)
    guard !add.overflow else { return false }
    self = add.partialValue
    return true
  }
}
