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

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros

extension RegisterDescription {
  func validate(
    in context: MacroContext<some ParsableMacro, some MacroExpansionContext>
  ) {
    // Validate bit range in each bit field.
    for bitField in self.bitFields {
      bitField.validate(in: context)
    }

    // FIXME: Validate bit range overlap across bit fields.
  }
}
