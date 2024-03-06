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

@XMLElement
public struct SVDDimensionElement {
  /// Define the number of elements in an array.
  public var dim: UInt64?
  /// Specify the address increment, in Bytes, between two neighboring array
  /// members in the address map.
  public var dimIncrement: UInt64?
  /// Do not define on peripheral level. By default, `<dimIndex>` is an
  /// integer value starting at 0.
  public var dimIndex: String?
  /// Specify the name of the C-type structure. If not defined, then the entry
  /// of the `<name>` element is used.
  public var dimName: String?
  /// Grouping element to create enumerations in the header file.
  public var dimArrayIndex: SVDDimensionArrayIndex?
}
