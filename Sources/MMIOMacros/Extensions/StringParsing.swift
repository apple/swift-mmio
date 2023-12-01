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

extension Substring {
  mutating func drop(character: Character) -> Bool {
    if self.first == character {
      self.removeFirst()
      return true
    }
    return false
  }

  mutating func consumeCharacter() -> Character? {
    guard !self.isEmpty else { return nil }
    return self.removeFirst()
  }

  mutating func consumeBinaryDigit() -> Int? {
    guard let first = self.first else { return nil }
    guard let ascii = first.asciiValue else { return nil }
    switch ascii {
    case UInt8(ascii: "0"), UInt8(ascii: "1"):
      _ = self.removeFirst()
      return Int(ascii - UInt8(ascii: "0"))
    default:
      return nil
    }
  }

  mutating func consumeOctalDigit() -> Int? {
    guard let first = self.first else { return nil }
    guard let ascii = first.asciiValue else { return nil }
    switch ascii {
    case UInt8(ascii: "0")..<UInt8(ascii: "8"):
      _ = self.removeFirst()
      return Int(ascii - UInt8(ascii: "0"))
    default:
      return nil
    }
  }

  mutating func consumeDecimalDigit() -> Int? {
    guard let first = self.first else { return nil }
    guard let ascii = first.asciiValue else { return nil }
    switch ascii {
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      _ = self.removeFirst()
      return Int(ascii - UInt8(ascii: "0"))
    default:
      return nil
    }
  }

  mutating func consumeHexadecimalDigit() -> Int? {
    guard let first = self.first else { return nil }
    guard let ascii = first.asciiValue else { return nil }
    switch ascii {
    case UInt8(ascii: "0")...UInt8(ascii: "9"):
      _ = self.removeFirst()
      return Int(ascii - UInt8(ascii: "0"))
    case UInt8(ascii: "a")...UInt8(ascii: "f"):
      _ = self.removeFirst()
      return Int(ascii - UInt8(ascii: "a") + 10)
    case UInt8(ascii: "A")...UInt8(ascii: "F"):
      _ = self.removeFirst()
      return Int(ascii - UInt8(ascii: "A") + 10)
    default:
      return nil
    }
  }

  // This isn't strictly correct but is good enough for our uses.
  mutating func consumeInteger() -> Int? {
    var value = 0
    let initialCount = self.count
    switch self.prefix(2) {
    case "0b":
      self.removeFirst(2)
      while !self.isEmpty {
        if self.drop(character: "_") { continue }
        guard let digit = self.consumeBinaryDigit() else { break }
        value = value * 2 + digit
      }
    case "0o":
      self.removeFirst(2)
      while !self.isEmpty {
        if self.drop(character: "_") { continue }
        guard let digit = self.consumeOctalDigit() else { break }
        value = value * 8 + digit
      }
    case "0x":
      self.removeFirst(2)
      while !self.isEmpty {
        if self.drop(character: "_") { continue }
        guard let digit = self.consumeHexadecimalDigit() else { break }
        value = value * 16 + digit
      }
    default:
      while !self.isEmpty {
        if self.drop(character: "_") { continue }
        guard let digit = self.consumeDecimalDigit() else { break }
        value = value * 10 + digit
      }
    }
    guard self.count != initialCount else { return nil }
    return value
  }
}
