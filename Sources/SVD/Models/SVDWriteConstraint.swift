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

/// Define constraints for writing values to a field.
///
/// You can choose between three options, which are mutually exclusive.
public enum SVDWriteConstraint {
  /// If true, only the last read value can be written.
  case writeAsRead(SVDWriteConstraintWriteAsRead)
  /// If true, only the values listed in the enumeratedValues list can be
  /// written.
  case useEnumeratedValues(Bool)
  /// Contains the following two elements:
  /// - minimum: Specify the smallest number to be written to the field.
  /// - maximum: Specify the largest number to be written to the field.
  case range(SVDWriteConstraintRange)
}

extension SVDWriteConstraint: Decodable {}

extension SVDWriteConstraint: Encodable {}

extension SVDWriteConstraint: Equatable {}

extension SVDWriteConstraint: Hashable {}

extension SVDWriteConstraint: Sendable {}

extension SVDWriteConstraint: XMLStructDecodable {
  public struct Fields: XMLFields {
    var writeAsRead = SVDWriteConstraintWriteAsRead.Fields()
    var writeAsReadFailed = false
    var useEnumeratedValues: Bool? = nil
    var useEnumeratedValuesFailed = false
    var range: SVDWriteConstraintRange? = nil
    var rangeFailed = false

    public init() {}

    public static var slotCount: Int {
      SVDWriteConstraintWriteAsRead.Fields.slotCount + 2
    }

    @inline(__always)
    public static func slot(
      for field: borrowing some CommonFieldDecoder & ~Escapable
    ) -> Int {
      let base = SVDWriteConstraintWriteAsRead.Fields.slotCount
      if field.matches("useEnumeratedValues") { return base }
      if field.matches("range") { return base + 1 }
      return SVDWriteConstraintWriteAsRead.Fields.slot(for: field)
    }

    public mutating func decode(
      slot: Int, from decoder: inout some CommonDecoder & ~Escapable
    ) throws(CodingError.Decoding) {
      // Like `try?` on each choice: an error removes only that choice.
      switch slot - SVDWriteConstraintWriteAsRead.Fields.slotCount {
      case 0:
        guard self.useEnumeratedValues == nil, !self.useEnumeratedValuesFailed
        else { return }
        do { self.useEnumeratedValues = try decoder.decode(Bool.self) } catch {
          self.useEnumeratedValuesFailed = true
        }
      case 1:
        guard self.range == nil, !self.rangeFailed else { return }
        do {
          self.range = try decoder.decode(SVDWriteConstraintRange.self)
        } catch {
          self.rangeFailed = true
        }
      default:
        do { try self.writeAsRead.decode(slot: slot, from: &decoder) } catch {
          self.writeAsReadFailed = true
        }
      }
    }

    public consuming func build() throws(CodingError.Decoding)
      -> SVDWriteConstraint?
    {
      if !self.writeAsReadFailed, let value = try? self.writeAsRead.build() {
        return .writeAsRead(value)
      }
      if let value = self.useEnumeratedValues {
        return .useEnumeratedValues(value)
      }
      if let value = self.range {
        return .range(value)
      }
      return nil
    }
  }
}
