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

import Foundation

/// An enumeratedValue defines a map between an unsigned integer and a string.
@XMLElement
public struct SVDEnumerationCase {
  //  /// String describing the semantics of the value. Can be displayed instead
  //  /// of the value.
  //  public var name: String?
  //  /// Extended string describing the value.
  //  public var description: String?
  //  /// The value of the case or the default value for undeclared cases.
  //  public var value: SVDEnumerationCaseValue
}

//extension SVDEnumerationCase {
//  enum CodingKeys: String, CodingKey {
//    case name
//    case description
//  }
//}

//extension SVDEnumerationCase: Decodable {
//  public init(from decoder: Decoder) throws {
//    let container = try decoder.container(keyedBy: CodingKeys.self)
//    self.name =
//      try container
//      .decodeIfPresent(String.self, forKey: .name)
//    self.description =
//      try container
//      .decodeIfPresent(String.self, forKey: .description)
//    self.value = try .init(from: decoder)
//  }
//}
//
//extension SVDEnumerationCase: Encodable {
//  public func encode(to encoder: Encoder) throws {
//    var container = encoder.container(keyedBy: CodingKeys.self)
//    try container.encode(self.name, forKey: .name)
//    try container.encode(self.description, forKey: .description)
//    try self.value.encode(to: encoder)
//  }
//}
