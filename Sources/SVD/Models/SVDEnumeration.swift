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

import Foundation

#if canImport(FoundationXML)
import FoundationXML
#endif

/// The concept of enumerated values creates a map between unsigned integers and
/// an identifier string.
///
/// In addition, a description string can be associated with each entry in the
/// map.
///
/// **Example**
/// - 0 `<->` disabled -> "The clock source clk0 is turned off."
/// - 1 `<->` enabled  -> "The clock source clk1 is running."
/// - 2 `<->` reserved -> "Reserved values. Do not use."
/// - 3 `<->` reserved -> "Reserved values. Do not use."
///
/// This information generates an enum in the device header file. The debugger
/// may use this information to display the identifier string as well as the
/// description. Just like symbolic constants making source code more readable,
/// the system view in the debugger becomes more instructive. The detailed
/// description can provide reference manual level details within the debugger.
@XMLElement
public struct SVDEnumeration {
  /// Makes a copy from a previously defined enumeratedValues section.
  ///
  /// No modifications are allowed. An enumeratedValues entry is referenced by
  /// its name. If the name is not unique throughout the description, it needs
  /// to be further qualified by specifying the associated field, register,
  /// and peripheral as required.
  ///
  /// For example:
  ///  - `field:                           clk.dis_en_enum`
  ///  - `register + field:                ctrl.clk.dis_en_enum`
  ///  - `peripheral + register + field:   timer0.ctrl.clk.dis_en_enum`
  @XMLAttribute
  public var derivedFrom: String?
  /// Identifier for the whole enumeration section.
  public var name: String?
  /// Identifier for the enumeration section.
  ///
  /// Overwrites the hierarchical enumeration type in the device header file.
  /// User is responsible for uniqueness across description.
  public var headerEnumName: String?
  /// This allows specifying two different enumerated values depending
  /// whether it is to be used for a read or a write access.
  ///
  /// If not specified, the default value read-write is used.
  public var usage: SVDEnumerationUsage?
  /// Describes a single entry in the enumeration.
  ///
  /// The number of required items depends on the bit-width of the associated
  /// field.
  public var enumeratedValue: [SVDEnumerationCase]
}

extension SVDEnumeration: Decodable {}

extension SVDEnumeration: Encodable {}

extension SVDEnumeration: Equatable {}

extension SVDEnumeration: Hashable {}

extension SVDEnumeration: Sendable {}
