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

import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct CompilerPluginMain: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    // MARK: RegisterBank macros
    RegisterBankMacro.self,
    RegisterBankOffsetMacro.self,
    // MARK: Register macros
    RegisterMacro.self,
    ReservedMacro.self,
    ReadWriteMacro.self,
    ReadOnlyMacro.self,
    WriteOnlyMacro.self,
  ]
}
