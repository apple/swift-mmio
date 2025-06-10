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

public enum SVDEnumerationCaseData {
  case value(SVDEnumerationCaseDataValue)
  case isDefault(SVDEnumerationCaseDataDefault)
}

extension SVDEnumerationCaseData: Sendable {}

extension SVDEnumerationCaseData: XMLElementInitializable {
  static func value(_ value: UInt64, mask: UInt64) -> Self {
    .value(.init(value: .init(value: value, mask: mask)))
  }

  static func isDefault() -> Self {
    .isDefault(.init(isDefault: true))
  }

  init(_ element: XMLElement) throws {
    if let value = try? SVDEnumerationCaseDataValue(element) {
      self = .value(value)
    } else if let value = try? SVDEnumerationCaseDataDefault(element) {
      self = .isDefault(value)
    } else {
      throw XMLError.unknownElement(element)
    }
  }
}

// FIXME: encoding / decoding container
extension SVDEnumerationCaseData: Decodable {}

extension SVDEnumerationCaseData: Encodable {}

extension SVDEnumerationCaseData: Equatable {}

extension SVDEnumerationCaseData: Hashable {}
