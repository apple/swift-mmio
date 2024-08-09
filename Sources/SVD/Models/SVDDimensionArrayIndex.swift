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

/// This information is used for generating an enum in the device header file.
/// The debugger may use this information to display the identifier string as
/// well as the description. Just like symbolic constants making source code
/// more readable, the system view in the debugger becomes more instructive.
@XMLElement
public struct SVDDimensionArrayIndex {
  /// Specify the base name of enumerations. Overwrites the hierarchical
  /// enumeration type in the device header file. User is responsible for
  /// uniqueness across description. The header-file generator uses the name
  /// of a peripheral or cluster as the base name for enumeration types. If
  /// `<headerEnumName>` element is specified, then this string is used.
  public var headerEnumName: String?
  /// Specify the values contained in the enumeration.
  public var enumeratedValue: [SVDEnumerationCase]
}

extension SVDDimensionArrayIndex: Decodable {}

extension SVDDimensionArrayIndex: Encodable {}

extension SVDDimensionArrayIndex: Equatable {}

extension SVDDimensionArrayIndex: Hashable {}
