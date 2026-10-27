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

extension SVDEnumerationCaseData: XMLElementDecodable {
  static func value(_ value: UInt64, mask: UInt64) -> Self {
    .value(.init(value: .init(value: value, mask: mask)))
  }

  static func isDefault() -> Self {
    .isDefault(.init(isDefault: true))
  }

  /// Builds each form of enumeration case data from the same element, and
  /// uses the first form that the element has.
  public struct XMLBuilder: XMLElementBuilder {
    var value = SVDEnumerationCaseDataValue.XMLBuilder()
    var isDefault = SVDEnumerationCaseDataDefault.XMLBuilder()

    public init() {}

    public mutating func attribute(_ name: XMLName, _ value: XMLText) {
      self.value.attribute(name, value)
      self.isDefault.attribute(name, value)
    }

    public static func child(
      _ name: XMLName,
      of builder: XMLBuilderPointer<Self>
    ) -> XMLFrame? {
      SVDEnumerationCaseDataValue.XMLBuilder.child(
        name, of: builder.member(\.value))
        ?? SVDEnumerationCaseDataDefault.XMLBuilder.child(
          name, of: builder.member(\.isDefault))
    }

    public mutating func build() throws(XMLBuildError) -> SVDEnumerationCaseData
    {
      if let value = try? self.value.build() {
        .value(value)
      } else if let value = try? self.isDefault.build() {
        .isDefault(value)
      } else {
        throw .failure(XMLError.unknownElement("enumerated value data"))
      }
    }
  }
}

// FIXME: encoding / decoding container
extension SVDEnumerationCaseData: Decodable {}

extension SVDEnumerationCaseData: Encodable {}

extension SVDEnumerationCaseData: Equatable {}

extension SVDEnumerationCaseData: Hashable {}
