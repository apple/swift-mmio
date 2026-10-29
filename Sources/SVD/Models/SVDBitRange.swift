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

public enum SVDBitRange {
  case lsbMsb(SVDBitRangeLsbMsb)
  case offsetWidth(SVDBitRangeOffsetWidth)
  case literal(SVDBitRangeLiteralContainer)
}

extension SVDBitRange: Decodable {}

extension SVDBitRange: Encodable {}

extension SVDBitRange: Equatable {}

extension SVDBitRange: Hashable {}

extension SVDBitRange: Sendable {}

extension SVDBitRange: XMLStructDecodable {
  public struct Fields: XMLFields {
    var lsbMsb = SVDBitRangeLsbMsb.Fields()
    var lsbMsbFailed = false
    var offsetWidth = SVDBitRangeOffsetWidth.Fields()
    var offsetWidthFailed = false
    var literal = SVDBitRangeLiteralContainer.Fields()
    var literalFailed = false

    public init() {}

    public static var slotCount: Int {
      SVDBitRangeLsbMsb.Fields.slotCount
        + SVDBitRangeOffsetWidth.Fields.slotCount
        + SVDBitRangeLiteralContainer.Fields.slotCount
    }

    @inline(__always)
    public static func slot(
      for field: borrowing some CommonFieldDecoder & ~Escapable
    ) -> Int {
      var base = 0
      let lsbMsb = SVDBitRangeLsbMsb.Fields.slot(for: field)
      if lsbMsb >= 0 { return base + lsbMsb }
      base += SVDBitRangeLsbMsb.Fields.slotCount
      let offsetWidth = SVDBitRangeOffsetWidth.Fields.slot(for: field)
      if offsetWidth >= 0 { return base + offsetWidth }
      base += SVDBitRangeOffsetWidth.Fields.slotCount
      let literal = SVDBitRangeLiteralContainer.Fields.slot(for: field)
      if literal >= 0 { return base + literal }
      return -1
    }

    public mutating func decode(
      slot: Int, from decoder: inout some CommonDecoder & ~Escapable
    ) throws(CodingError.Decoding) {
      // Like `try?` on each choice: an error removes only that choice.
      var slot = slot
      if slot < SVDBitRangeLsbMsb.Fields.slotCount {
        do { try self.lsbMsb.decode(slot: slot, from: &decoder) } catch {
          self.lsbMsbFailed = true
        }
        return
      }
      slot -= SVDBitRangeLsbMsb.Fields.slotCount
      if slot < SVDBitRangeOffsetWidth.Fields.slotCount {
        do { try self.offsetWidth.decode(slot: slot, from: &decoder) } catch {
          self.offsetWidthFailed = true
        }
        return
      }
      slot -= SVDBitRangeOffsetWidth.Fields.slotCount
      do { try self.literal.decode(slot: slot, from: &decoder) } catch {
        self.literalFailed = true
      }
    }

    public consuming func build() throws(CodingError.Decoding) -> SVDBitRange? {
      if !self.lsbMsbFailed, let value = try? self.lsbMsb.build() {
        return .lsbMsb(value)
      }
      if !self.offsetWidthFailed, let value = try? self.offsetWidth.build() {
        return .offsetWidth(value)
      }
      if !self.literalFailed, let value = try? self.literal.build() {
        return .literal(value)
      }
      return nil
    }
  }
}
