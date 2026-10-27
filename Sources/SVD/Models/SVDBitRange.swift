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

extension SVDBitRange: XMLElementDecodable {
  /// Builds each form of bit range from the same element, and uses the first
  /// form that the element has.
  public struct XMLBuilder: XMLElementBuilder {
    var lsbMsb = SVDBitRangeLsbMsb.XMLBuilder()
    var offsetWidth = SVDBitRangeOffsetWidth.XMLBuilder()
    var literal = SVDBitRangeLiteralContainer.XMLBuilder()

    public init() {}

    public mutating func attribute(_ name: XMLName, _ value: XMLText) {
      self.lsbMsb.attribute(name, value)
      self.offsetWidth.attribute(name, value)
      self.literal.attribute(name, value)
    }

    public static func child(
      _ name: XMLName,
      of builder: XMLBuilderPointer<Self>
    ) -> XMLFrame? {
      SVDBitRangeLsbMsb.XMLBuilder.child(name, of: builder.member(\.lsbMsb))
        ?? SVDBitRangeOffsetWidth.XMLBuilder.child(
          name, of: builder.member(\.offsetWidth))
        ?? SVDBitRangeLiteralContainer.XMLBuilder.child(
          name, of: builder.member(\.literal))
    }

    public mutating func build() throws(XMLBuildError) -> SVDBitRange {
      if let value = try? self.lsbMsb.build() {
        .lsbMsb(value)
      } else if let value = try? self.offsetWidth.build() {
        .offsetWidth(value)
      } else if let value = try? self.literal.build() {
        .literal(value)
      } else {
        throw .failure(XMLError.unknownElement("bit range"))
      }
    }
  }
}
