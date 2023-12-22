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

enum SwiftIntegerPrefix: String, CaseIterable {
  case binary = "0b"
  case octal = "0o"
  case hexadecimal = "0x"
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

      let prefix = Parser<Input, SwiftIntegerPrefix>.cases().run(&input)

      var value = Output(0)
      var digitsConsumed = false
      loop: while !input.isEmpty {
        switch prefix {
        case .binary:
          guard let digit = Parser.binaryDigit().run(&input) else { break loop }
          value = value * 2 + digit
        case .octal:
          guard let digit = Parser.octalDigit().run(&input) else { break loop }
          value = value * 8 + digit
        case nil:
          guard let digit = Parser.decimalDigit().run(&input) else { break loop }
          value = value * 10 + digit
        case .hexadecimal:
          guard let digit = Parser.hexadecimalDigit().run(&input) else { break loop }
          value = value * 16 + digit
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
}

extension Parser where Input == Substring, Output: FixedWidthInteger {
  public static func scaledNonNegativeInteger(_: Output.Type = Output.self) -> Self {
    Self { input in
      let original = input

      if input.first?.asciiValue == UInt8(ascii: "+") {
        input.removeFirst()
      }

      let prefix = Parser<Input, ScaledNonNegativeIntegerPrefix>
        .cases().run(&input)

      var value = Output(0)
      var digitsConsumed = false
      loop: while !input.isEmpty {
        switch prefix {
        case .binary:
          guard let digit = Parser.binaryDigit().run(&input) else { break loop }
          value = value * 2 + digit
        case nil:
          guard let digit = Parser.decimalDigit().run(&input) else { break loop }
          value = value * 10 + digit
        case .hexadecimal, .hexadecimal2:
          guard let digit = Parser.hexadecimalDigit().run(&input) else { break loop }
          value = value * 16 + digit
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

extension Parser where Input == Substring, Output: FixedWidthInteger {
  public static func binaryDigit(_: Output.Type = Output.self) -> Self {
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

  public static func octalDigit(_: Output.Type = Output.self) -> Self {
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

  public static func decimalDigit(_: Output.Type = Output.self) -> Self {
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

  public static func hexadecimalDigit(_: Output.Type = Output.self) -> Self {
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
