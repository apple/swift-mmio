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

/// A peripheral can have multiple interrupts. This entry allows the debugger to
/// show interrupt names instead of interrupt numbers.
@XMLElement
public struct SVDInterrupt {
  /// The string represents the interrupt name.
  public var name: String
  /// The string describes the interrupt.
  public var description: String?
  /// Represents the enumeration index value associated to the interrupt.
  public var value: UInt64
}
