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

#if canImport(FoundationXML)
import FoundationXML
#else
import Foundation
#endif

/// A bit-field has a name that is unique within the register.
///
/// The position and size within the register can be described in two ways:
/// - by the combination of the least significant bit's position (lsb) and the
///   most significant bit's position (msb), or
/// - the lsb and the bit-width of the field.
///
/// A field may define an enumeratedValue in order to make the display more
/// intuitive to read.
@XMLElement
public struct SVDField {
  /// Specify the field name from which to inherit data. Elements specified
  /// subsequently override inherited values.
  ///
  /// Always use the full qualifying path, which must start with the
  /// peripheral `<name>`, when deriving from another scope. (for example, in
  /// perisperhal A and registerX, derive from
  /// peripheralA.registerYY.fieldYY).
  ///
  /// You can use the field `<name>` only when both fields are in the same
  /// scope. No relative paths will work.
  ///
  /// - Remark: When deriving, it is mandatory to specify at least the
  /// `<name>` and `<description>`.
  @XMLAttribute
  public var derivedFrom: String?
  /// Specifies the number of array elements (dim), the address offset between
  /// consecutive array elements and a comma separated list of strings used to
  /// identify each element in the array.
  @XMLInlineElement
  public var dimensionElement: SVDDimensionElement
  /// Name string used to identify the field. Field names must be unique
  /// within a register.
  public var name: String
  /// String describing the details of the register.
  public var description: String?
  /// Specification of the bit position of the field within the register.
  @XMLInlineElement
  public var bitRange: SVDBitRange
  /// Predefined strings set the access type. The element can be omitted if
  /// access rights get inherited from parent elements.
  public var access: SVDAccess?
  /// Describe the manipulation of data written to a field. If not specified,
  /// the value written to the field is the value stored in the field.
  public var modifiedWriteValues: SVDModifiedWriteValues?
  /// Three mutually exclusive options exist to set write-constraints.
  public var writeConstraint: SVDWriteConstraint?
  /// If set, it specifies the side effect following a read operation. If not
  /// set, the field is not modified after a read.
  ///
  /// Debuggers are not expected to read this field location unless explicitly
  /// instructed by the user.
  public var readAction: SVDReadAction?
  /// Next lower level of description.
  public var enumeratedValues: SVDEnumeration?
}
