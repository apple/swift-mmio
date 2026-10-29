//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

@_exported public import NewCodable

/// The members of a type while a struct decoder decodes its fields.
///
/// Each member that can take a field has one or more slots. A type that
/// embeds another type inline (`@XMLInlineElement`) also takes the slots of
/// that type, after its own slots.
public protocol XMLFields {
  associatedtype Value

  init()

  /// The number of slots.
  static var slotCount: Int { get }

  /// Returns the slot for a field, or -1 if no member takes the field.
  static func slot(for field: borrowing some CommonFieldDecoder & ~Escapable)
    -> Int

  /// Decodes the value of a field into its slot.
  mutating func decode(
    slot: Int, from decoder: inout some CommonDecoder & ~Escapable
  ) throws(CodingError.Decoding)

  /// Returns the value, or `nil` if a required member is missing.
  consuming func build() throws(CodingError.Decoding) -> Value?
}

/// A type that decodes from a struct, one field at a time.
public protocol XMLStructDecodable: CommonDecodable {
  associatedtype Fields: XMLFields where Fields.Value == Self
}

extension XMLStructDecodable {
  @inlinable
  public static func decode(
    from decoder: inout some CommonDecoder & ~Escapable
  ) throws(CodingError.Decoding) -> Self {
    try decoder.decodeStruct { structDecoder throws(CodingError.Decoding) in
      var fields = Fields()
      var slot = -1
      try structDecoder.decodeEachField { field throws(CodingError.Decoding) in
        slot = Fields.slot(for: field)
      } andValue: { value throws(CodingError.Decoding) in
        guard slot >= 0 else { return }
        try fields.decode(slot: slot, from: &value)
      }
      guard let value = try fields.build() else {
        throw CodingError.valueNotFound(expectedType: Self.self)
      }
      return value
    }
  }
}

extension CommonDecodable where Self: LosslessStringConvertible {
  @inlinable
  public static func decode(
    from decoder: inout some CommonDecoder & ~Escapable
  ) throws(CodingError.Decoding) -> Self {
    let string = try decoder.decode(String.self)
    guard let value = Self(string) else {
      throw CodingError.dataCorrupted(
        debugDescription: "Invalid value '\(string)' for \(Self.self)")
    }
    return value
  }
}
