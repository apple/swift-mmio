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

@XMLElement
public struct SVDRegister {
  /// Specify the register name from which to inherit data.
  ///
  /// Elements specified subsequently override inherited values.
  ///
  /// Always use the full qualifying path, which must start with the
  /// peripheral `<name>`, when deriving from another scope. (for example,
  /// in peripheral B, derive from peripheralA.registerX).
  ///
  /// You can use the register `<name>` only when both registers are in the
  /// same scope. No relative paths will work.
  ///
  /// - Remark: When deriving, it is mandatory to specify at least the
  /// `<name>`, the `<description>`, and the `<addressOffset>`.
  @XMLAttribute
  public var derivedFrom: String?
  /// Specifies the number of array elements (dim), the address offset between
  /// consecutive array elements and a comma separated list of strings used to
  /// identify each element in the array.
  @XMLInlineElement
  public var dimensionElement: SVDDimensionElement?
  /// String to identify the register.
  ///
  /// Register names are required to be unique within the scope of a peripheral.
  /// You can use the placeholder `%s`, which is replaced by the dimIndex
  /// substring. Use the placeholder `[%s]` only at the end of the identifier to
  /// generate arrays in the header file. The placeholder `[%s]` cannot be used
  /// together with dimIndex.
  public var name: String
  /// When specified, then this string can be used by a graphical frontend to
  /// visualize the register.
  ///
  /// Otherwise the name element is displayed. displayName may contain special
  /// characters and white spaces. You can use the placeholder `%s`, which is
  /// replaced by the dimIndex substring. Use the placeholder `[%s]` only at the
  /// end of the identifier. The placeholder `[%s]` cannot be used together
  /// with dimIndex.
  public var displayName: String?
  /// String describing the details of the register.
  public var description: String?
  /// Specifies a group name associated with all alternate register that have
  /// the same name.
  ///
  /// At the same time, it indicates that there is a register definition
  /// allocating the same absolute address in the address space.
  public var alternateGroup: String?
  /// This tag can reference a register that has been defined above to current
  /// location in the description and that describes the memory location
  /// already.
  ///
  /// This tells the SVDConv's address checker that the redefinition of this
  /// particular register is intentional. The register name needs to be unique
  /// within the scope of the current peripheral. A register description is
  /// defined either for a unique address location or could be a redefinition of
  /// an already described address. In the latter case, the register can be
  /// either marked alternateRegister and needs to have a unique name, or it can
  /// have the same register name but is assigned to a register subgroup through
  /// the tag alternateGroup (specified in version 1.0).
  public var alternateRegister: String?
  /// Define the address offset relative to the enclosing element.
  public var addressOffset: UInt64
  /// Elements specify the default values for register size, access permission
  /// and reset value.
  ///
  /// These default values are inherited to all fields contained in this
  /// register.
  @XMLInlineElement
  public var registerProperties: SVDRegisterProperties = .init()
  /// It can be useful to assign a specific native C datatype to a register.
  ///
  /// This helps avoiding type casts. For example, if a 32 bit register shall
  /// act as a pointer to a 32 bit unsigned data item, then dataType can be
  /// set to `uint32_t *`.
  public var dataType: SVDDataType?
  /// Element to describe the manipulation of data written to a register.
  ///
  /// If not specified, the value written to the field is the value stored in
  /// the field. The other options define bitwise operations:
  public var modifiedWriteValues: SVDModifiedWriteValues?
  /// Mutually exclusive options exist to set write-constraints.
  public var writeConstraint: SVDWriteConstraint?
  /// If set, it specifies the side effect following a read operation.
  ///
  /// If not set, the register is not modified.
  ///
  /// Debuggers are not expected to read this register location unless
  /// explicitly instructed by the user.
  public var readAction: SVDReadAction?
  /// In case a register is subdivided into bit fields, it should be reflected
  /// in the SVD description file to create bit-access macros and bit-field
  /// structures in the header file.
  public var fields: SVDFields?
}

extension SVDRegister: Decodable {}

extension SVDRegister: Encodable {}

extension SVDRegister: Equatable {}

extension SVDRegister: Hashable {}

extension SVDRegister: Sendable {}
