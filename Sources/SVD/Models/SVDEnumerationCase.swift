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

#if canImport(FoundationXML)
import FoundationXML
#endif

/// An enumeratedValue defines a map between an unsigned integer and a string.
@XMLElement
public struct SVDEnumerationCase {
  /// String describing the semantics of the value.
  ///
  /// Can be displayed instead of the value.
  public var name: String?
  /// Extended string describing the value.
  public var description: String?
  /// The value of the case or the default value for undeclared cases.
  @XMLInlineElement
  public var data: SVDEnumerationCaseData
}

extension SVDEnumerationCase: Decodable {}

extension SVDEnumerationCase: Encodable {}

extension SVDEnumerationCase: Equatable {}

extension SVDEnumerationCase: Hashable {}

extension SVDEnumerationCase: Sendable {}
