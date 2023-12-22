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

/// Grouping element to define bit-field properties of a register.
@XMLElement
public struct SVDFields {
  /// Define the bit-field properties of a register.
  public var field: [SVDField]
}
