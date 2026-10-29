//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

public import XML

public enum SVDEnumerationCaseData {
  case value(SVDEnumerationCaseDataValue)
  case isDefault(SVDEnumerationCaseDataDefault)
}

extension SVDEnumerationCaseData: Sendable {}

extension SVDEnumerationCaseData {
  static func value(_ value: UInt64, mask: UInt64) -> Self {
    .value(.init(value: .init(value: value, mask: mask)))
  }

  static func isDefault() -> Self {
    .isDefault(.init(isDefault: true))
  }
}

// FIXME: encoding / decoding container
extension SVDEnumerationCaseData: Decodable {}

extension SVDEnumerationCaseData: Encodable {}

extension SVDEnumerationCaseData: Equatable {}

extension SVDEnumerationCaseData: Hashable {}

extension SVDEnumerationCaseData: XMLStructDecodable {
  public struct Fields: XMLFields {
    var value = SVDEnumerationCaseDataValue.Fields()
    var valueFailed = false
    var isDefault = SVDEnumerationCaseDataDefault.Fields()
    var isDefaultFailed = false

    public init() {}

    public static var slotCount: Int {
      SVDEnumerationCaseDataValue.Fields.slotCount
        + SVDEnumerationCaseDataDefault.Fields.slotCount
    }

    @inline(__always)
    public static func slot(
      for field: borrowing some CommonFieldDecoder & ~Escapable
    ) -> Int {
      let value = SVDEnumerationCaseDataValue.Fields.slot(for: field)
      if value >= 0 { return value }
      let isDefault = SVDEnumerationCaseDataDefault.Fields.slot(for: field)
      if isDefault >= 0 {
        return SVDEnumerationCaseDataValue.Fields.slotCount + isDefault
      }
      return -1
    }

    public mutating func decode(
      slot: Int, from decoder: inout some CommonDecoder & ~Escapable
    ) throws(CodingError.Decoding) {
      // Like `try?` on each choice: an error removes only that choice.
      if slot < SVDEnumerationCaseDataValue.Fields.slotCount {
        do { try self.value.decode(slot: slot, from: &decoder) } catch {
          self.valueFailed = true
        }
        return
      }
      let slot = slot - SVDEnumerationCaseDataValue.Fields.slotCount
      do { try self.isDefault.decode(slot: slot, from: &decoder) } catch {
        self.isDefaultFailed = true
      }
    }

    public consuming func build() throws(CodingError.Decoding)
      -> SVDEnumerationCaseData?
    {
      if !self.valueFailed, let value = try? self.value.build() {
        return .value(value)
      }
      if !self.isDefaultFailed, let value = try? self.isDefault.build() {
        return .isDefault(value)
      }
      return nil
    }
  }
}
