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

enum IntegerLiteralBase {
  case binary
  case octal
  case decimal
  case hexadecimal

  func value<Output>() -> Output
  where Output: FixedWidthInteger {
    switch self {
    case .binary: 2
    case .octal: 8
    case .decimal: 10
    case .hexadecimal: 16
    }
  }
}

extension FixedWidthInteger {
  mutating func incrementalParseAppend(
    digit: Self,
    base: IntegerLiteralBase
  ) -> Bool {
    let multiply = self.multipliedReportingOverflow(by: base.value())
    guard !multiply.overflow else { return false }
    let add = multiply.partialValue.addingReportingOverflow(digit)
    guard !add.overflow else { return false }
    self = add.partialValue
    return true
  }
}

extension Parser where Input == Substring, Output: FixedWidthInteger {
  static func digit(
    _: Output.Type = Output.self,
    base: IntegerLiteralBase
  ) -> Self {
    switch base {
    case .binary: Self.binaryDigit()
    case .octal: Self.octalDigit()
    case .decimal: Self.decimalDigit()
    case .hexadecimal: Self.hexadecimalDigit()
    }
  }

  static func binaryDigit(_: Output.Type = Output.self) -> Self {
    Self { input in
      guard let ascii = input.first?.asciiValue else { return nil }
      switch ascii {
      case UInt8(ascii: "0"), UInt8(ascii: "1"):
        _ = input.removeFirst()
        return Output(ascii - UInt8(ascii: "0"))
      default:
        return nil
      }
    }
  }

  static func octalDigit(_: Output.Type = Output.self) -> Self {
    Self { input in
      guard let ascii = input.first?.asciiValue else { return nil }
      switch ascii {
      case UInt8(ascii: "0")..<UInt8(ascii: "8"):
        _ = input.removeFirst()
        return Output(ascii - UInt8(ascii: "0"))
      default:
        return nil
      }
    }
  }

  static func decimalDigit(_: Output.Type = Output.self) -> Self {
    Self { input in
      guard let ascii = input.first?.asciiValue else { return nil }
      switch ascii {
      case UInt8(ascii: "0")...UInt8(ascii: "9"):
        _ = input.removeFirst()
        return Output(ascii - UInt8(ascii: "0"))
      default:
        return nil
      }
    }
  }

  static func hexadecimalDigit(_: Output.Type = Output.self) -> Self {
    Self { input in
      guard let ascii = input.first?.asciiValue else { return nil }
      switch ascii {
      case UInt8(ascii: "0")...UInt8(ascii: "9"):
        _ = input.removeFirst()
        return Output(ascii - UInt8(ascii: "0"))
      case UInt8(ascii: "a")...UInt8(ascii: "f"):
        _ = input.removeFirst()
        return Output(ascii - UInt8(ascii: "a") + 10)
      case UInt8(ascii: "A")...UInt8(ascii: "F"):
        _ = input.removeFirst()
        return Output(ascii - UInt8(ascii: "A") + 10)
      default:
        return nil
      }
    }
  }
}

enum SwiftIntegerPrefix: String, CaseIterable {
  case binary = "0b"
  case octal = "0o"
  case hexadecimal = "0x"

  var base: IntegerLiteralBase {
    switch self {
    case .binary: .binary
    case .octal: .octal
    case .hexadecimal: .hexadecimal
    }
  }
}

extension Parser where Input == Substring, Output: FixedWidthInteger {
  public static func swiftInteger(_: Output.Type = Output.self) -> Self {
    Self { input in
      let original = input

      var positive = true
      switch input.first?.asciiValue {
      case UInt8(ascii: "-"):
        positive = false
        input.removeFirst()
      case UInt8(ascii: "+"):
        positive = true
        input.removeFirst()
      default:
        break
      }

      let base =
        Parser<Input, SwiftIntegerPrefix>.cases().run(&input)?.base
        ?? .decimal

      var value = Output(0)
      var digitsConsumed = false
      loop: while !input.isEmpty {
        // Attempt to parse a digit.
        guard let digit = Parser.digit(base: base).run(&input)
        else { break loop }

        // Add the digit to the parsed value.
        guard value.incrementalParseAppend(digit: digit, base: base)
        else {
          // Exit early on overflow.
          input = original
          return nil
        }

        digitsConsumed = true
        while input.first?.asciiValue == UInt8(ascii: "_") {
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
}

enum ScaledNonNegativeIntegerPrefix: String, CaseIterable {
  case binary = "#"
  case hexadecimal = "0x"
  case hexadecimal2 = "0X"

  var base: IntegerLiteralBase {
    switch self {
    case .binary: .binary
    case .hexadecimal, .hexadecimal2: .hexadecimal
    }
  }
}

extension Parser where Input == Substring, Output: FixedWidthInteger {
  public static func scaledNonNegativeInteger(
    _: Output.Type = Output.self
  ) -> Self {
    Self { input in
      let original = input

      if input.first?.asciiValue == UInt8(ascii: "+") {
        input.removeFirst()
      }

      let base =
        Parser<Input, ScaledNonNegativeIntegerPrefix>
        .cases().run(&input)?.base ?? .decimal

      var value = Output(0)
      var digitsConsumed = false
      loop: while !input.isEmpty {
        // Attempt to parse a digit.
        guard let digit = Parser.digit(base: base).run(&input)
        else { break loop }

        // Add the digit to the parsed value.
        guard value.incrementalParseAppend(digit: digit, base: base)
        else {
          // Exit early on overflow.
          input = original
          return nil
        }
        digitsConsumed = true
      }

      guard digitsConsumed else {
        input = original
        return nil
      }

      // Parse suffix.
      switch input.first {
      case "k", "K":
        value *= 1_000
        input.removeFirst()
      case "m", "M":
        value *= 1_000_000
        input.removeFirst()
      case "g", "G":
        value *= 1_000_000_000
        input.removeFirst()
      case "t", "T":
        value *= 1_000_000_000_000
        input.removeFirst()
      case nil:
        break
      default:
        input = original
        return nil
      }

      return value
    }
  }
}

enum EnumeratedValueDataTypePrefix: String, CaseIterable {
  case binary = "#"
  case binary2 = "0b"
  case hexadecimal = "0x"
  case hexadecimal2 = "0X"

  var base: IntegerLiteralBase {
    switch self {
    case .binary, .binary2: .binary
    case .hexadecimal, .hexadecimal2: .hexadecimal
    }
  }
}

extension Parser where Input == Substring {
  static func binaryOrAnyDigit<Integer>(
    _: Integer.Type = Integer.self
  ) -> Parser<Input, (Integer, Integer)> where Integer: FixedWidthInteger {
    Parser<Input, (Integer, Integer)> { input in
      guard let ascii = input.first?.asciiValue else { return nil }
      switch ascii {
      case UInt8(ascii: "0"), UInt8(ascii: "1"):
        _ = input.removeFirst()
        return (Integer(ascii - UInt8(ascii: "0")), 1)
      case UInt8(ascii: "x"), UInt8(ascii: "X"):
        _ = input.removeFirst()
        return (0, 0)
      default:
        return nil
      }
    }
  }

  public static func enumeratedValueDataType<Integer>(
    _: Integer.Type = Integer.self
  ) -> Parser<Input, (Integer, Integer)> where Integer: FixedWidthInteger {
    Parser<Input, (Integer, Integer)> { input in
      let original = input

      if input.first?.asciiValue == UInt8(ascii: "+") {
        input.removeFirst()
      }

      let base =
        Parser<Input, EnumeratedValueDataTypePrefix>
        .cases().run(&input)?.base ?? .decimal

      var value = Integer(0)
      var mask = Integer(0) &- 1
      var digitsConsumed = false
      loop: while !input.isEmpty {
        switch base {
        case .binary:
          // Attempt to parse a digit.
          guard let digit = Parser.binaryOrAnyDigit(Integer.self).run(&input)
          else { break loop }

          // Add the digit to the parsed value.
          guard value.incrementalParseAppend(digit: digit.0, base: base)
          else {
            // Exit early on overflow.
            input = original
            return nil
          }

          mask = mask << 1 | digit.1
        default:
          // Attempt to parse a digit.
          guard let digit = Parser<Input, Integer>.digit(base: base).run(&input)
          else { break loop }

          // Add the digit to the parsed value.
          guard value.incrementalParseAppend(digit: digit, base: base)
          else {
            // Exit early on overflow.
            input = original
            return nil
          }
        }
        digitsConsumed = true
      }

      guard digitsConsumed else {
        input = original
        return nil
      }

      return (value, mask)
    }
  }
}
