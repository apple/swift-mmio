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

import CLLDB

/// Top level library entry point.
///
/// This function serves as lldb's entry point for initializing a plugin. It
/// must use the `C` calling and must match the mangled name of the `C++`
/// function: `bool lldb::PluginInitialize(lldb::SBDebugger debugger)`.
@_cdecl("_ZN4lldb16PluginInitializeENS_10SBDebuggerE")
func pluginInitialize(debugger: UnsafeMutableRawPointer) -> Bool {
  let debugger = debugger.bindMemory(to: lldb.SBDebugger.self, capacity: 1)
  svd2lldb = SVD2LLDB(debugger: &debugger.pointee)
  return true
}

var svd2lldb: SVD2LLDB!
