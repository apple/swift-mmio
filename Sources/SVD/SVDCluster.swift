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

/// Cluster describes a sequence of neighboring registers within a peripheral.
/// A `<cluster>` specifies the addressOffset relative to the baseAddress of the
/// grouping element. All `<register>` elements within a `<cluster>` specify
/// their addressOffset relative to the cluster base address
/// `(<peripheral.baseAddress> + <cluster.addressOffset>)`.
///
/// Multiple `<register>` and `<cluster>` sections may occur in any order. Since
/// version 1.3 of the specification, the nesting of `<cluster>` elements is
/// supported. Nested clusters express hierarchical structures of registers. It
/// is predominantly targeted at the generation of device header files to create
/// a C-data structure within the peripheral structure instead of a flat list of
/// registers. Note, you can also specify an array of a cluster using the
/// `<dim>` element.
@XMLElement
public struct SVDCluster {
  /// Specify the cluster name from which to inherit data. Elements specified
  /// subsequently override inherited values.
  ///
  /// Always use the full qualifying path, which must start with the
  /// peripheral `<name>`, when deriving from another scope. (for example, in
  /// peripheral B, derive from `peripheralA.clusterX`).
  ///
  /// You can use the cluster `<name>` when both clusters are in the same
  /// scope. No relative paths will work.
  ///
  /// - Remark: When deriving a cluster, it is mandatory to specify at least
  /// the `<name>`, the `<description>`, and the `<addressOffset>`.
  @XMLAttribute
  public var derivedFrom: String?
  /// Specifies the number of array elements (dim), the address offset between
  /// consecutive array elements and a comma separated list of strings used to
  /// identify each element in the array.
  @XMLInlineElement
  public var dimensionElement: SVDDimensionElement
  /// String to identify the cluster. Cluster names are required to be unique
  /// within the scope of a peripheral. A list of cluster names can be build
  /// using the placeholder `%s`. Use the placeholder `[%s]` at the end of the
  /// identifier to generate arrays in the header file. The placeholder `[%s]`
  /// cannot be used together with `<dimIndex>`.
  public var name: String
  /// String describing the details of the register cluster.
  public var description: String
  /// Specify the name of the original cluster if this cluster provides an
  /// alternative description.
  public var alternateCluster: String?
  /// Specify the struct type name created in the device header file. If not
  /// specified, then the name of the cluster is used.
  public var headerStructName: String?
  /// Cluster address relative to the `<baseAddress>` of the peripheral.
  public var addressOffset: UInt64
  /// Elements specify the default values for register size, access permission
  /// and reset value. These default values are inherited to all fields
  /// contained in this cluster.
  @XMLInlineElement
  public var registerProperties: SVDRegisterProperties
  /// Define the sequence of register clusters.
  public var cluster: [SVDCluster]?
  /// Define the sequence of registers.
  public var register: [SVDRegister]?
}
