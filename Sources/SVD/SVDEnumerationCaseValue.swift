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

public enum SVDEnumerationCaseValue {
  // FIXME: enumeratedValueDataType -> SVDEnumerationCaseValueData
  case value(UInt64)
  case isDefault(Bool)
}

extension SVDEnumerationCaseValue {
  //  enum CodingKeys: String, XMLChoiceCodingKey {
  //    case value
  //    case isDefault
  //  }
}

//extension SVDEnumerationCaseValue: Decodable {
//  public init(from decoder: Decoder) throws {
//    let container = try decoder.container(keyedBy: CodingKeys.self)
//    if let value = try? container.decode(UInt64.self, forKey: .value) {
//      self = .value(value)
//    } else if let value = try? container.decode(Bool.self, forKey: .isDefault) {
//      self = .isDefault(value)
//    } else {
//      throw DecodingError.dataCorrupted(
//        .init(
//          codingPath: decoder.codingPath,
//          debugDescription: "No valid choice."))
//    }
//  }
//}
//
//extension SVDEnumerationCaseValue: Encodable {
//  public func encode(to encoder: Encoder) throws {
//    var container = encoder.container(keyedBy: CodingKeys.self)
//    switch self {
//    case .value(let value):
//      try container.encode(value, forKey: .value)
//    case .isDefault(let value):
//      try container.encode(value, forKey: .isDefault)
//    }
//  }
//}
