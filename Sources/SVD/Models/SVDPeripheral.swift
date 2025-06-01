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

/// Each peripheral describes all registers belonging to that peripheral.
///
/// - The address range allocated by a peripheral is defined through one or more
///   address blocks.
/// - An address block and register addresses are specified relative to the base
///   address of a peripheral. The address block information can be used for
///   constructing a memory map for the device peripherals.
@XMLElement
public struct SVDPeripheral {
  /// Specify the peripheral name from which to inherit data.
  ///
  /// Elements specified subsequently override inherited values.
  @XMLAttribute
  public var derivedFrom: String?
  /// Specifies the number of array elements (dim), the address offset between
  /// consecutive array elements and a comma separated list of strings used to
  /// identify each element in the array.
  @XMLInlineElement
  public var dimensionElement: SVDDimensionElement?
  /// The string identifies the peripheral.
  ///
  /// Peripheral names are required to be unique for a device. The name needs to
  /// be an ANSI C identifier to generate the header file. You can use the
  /// placeholder `[%s]` to create arrays.
  public var name: String
  /// The string specifies the version of this peripheral description.
  public var version: String?
  /// The string provides an overview of the purpose and functionality of the
  /// peripheral.
  public var description: String?
  /// All address blocks in the memory space of a device are assigned to a
  /// unique peripheral by default.
  ///
  /// If multiple peripherals describe the same address blocks, then this needs
  /// to be specified explicitly. A peripheral redefining an address block needs
  /// to specify the name of the peripheral that is listed first in the
  /// description.
  public var alternatePeripheral: String?
  /// Define a name under which the System Viewer is showing this peripheral.
  public var groupName: String?
  /// Define a string as prefix.
  ///
  /// All register names of this peripheral get this prefix.
  public var prependToName: String?
  /// Define a string as suffix.
  ///
  /// All register names of this peripheral get this suffix.
  public var appendToName: String?
  /// Specify the base name of C structures.
  ///
  /// The header-file generator uses the name of a peripheral as the base name
  /// for the C structure type. If `<headerStructName>` element is specified,
  /// then this string is used instead of the peripheral name; useful when
  /// multiple peripherals get derived and a generic type name should be used.
  public var headerStructName: String?
  /// Define a C-language compliant logical expression returning a `true` or
  /// `false` result.
  ///
  /// If `true`, refreshing the display for this peripheral is disabled and
  /// related accesses by the debugger are suppressed.
  ///
  /// Only constants and references to other registers contained in the
  /// description are allowed: `<peripheral>-><register>-><field>`, for
  /// example, `(System->ClockControl->apbEnable == 0)`. The following
  /// operators are allowed in the expression `[&&,||, ==, !=, >>, <<, &, |]`.
  ///
  /// > Attention:
  /// > Use this feature only in cases where accesses from the debugger to
  /// > registers of un-clocked peripherals result in severe debugging
  /// > failures. SVD is intended to provide static information and does not
  /// > include any run-time computation or functions. Such capabilities can
  /// > be added by the tools, and is beyond the scope of this description
  /// > language.
  public var disableCondition: String?
  /// Lowest address reserved or used by the peripheral.
  public var baseAddress: UInt64
  /// Elements specify the default values for register size, access permission
  /// and reset value.
  ///
  /// These default values are inherited to all fields contained in this
  /// peripheral.
  @XMLInlineElement
  public var registerProperties: SVDRegisterProperties = .init()
  /// Specify an address range uniquely mapped to this peripheral.
  ///
  /// A peripheral must have at least one address block, but can allocate
  /// multiple distinct address ranges. If a peripheral is derived from
  /// another peripheral, the addressBlock is not mandatory.
  public var addressBlock: SVDAddressBlock?  // FIXME: Array<SVDAddressBlock>
  /// A peripheral can have multiple associated interrupts.
  ///
  /// This entry allows the debugger to show interrupt names instead of
  /// interrupt numbers.
  public var interrupt: SVDInterrupt?  // FIXME: Array<SVDInterrupt>
  /// Group to enclose register definitions.
  public var registers: SVDRegisters?
}

extension SVDPeripheral: Decodable {}

extension SVDPeripheral: Encodable {}

extension SVDPeripheral: Equatable {}

extension SVDPeripheral: Hashable {}

extension SVDPeripheral: Sendable {}
