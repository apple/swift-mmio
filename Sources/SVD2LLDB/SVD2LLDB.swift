//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import LLDB
import Foundation
import MMIOUtilities
import SVD

final class SVD2LLDB {
  // swift-format-ignore: NeverUseImplicitlyUnwrappedOptionals
  /// The main instance of SVD2LLDB created on plugin initialization. This value
  /// will always be valid throughout the duration of the plugin's execution.
  static var shared: SVD2LLDB!

  var device: SVDDevice?

  init(device: SVDDevice?) {
    self.device = device
  }
}

extension SVD2LLDB {
  convenience init(debugger: inout lldb.SBDebugger) {
    self.init(device: nil)
    var interpreter = debugger.GetCommandInterpreter()
    var svdCommand = interpreter.AddMultiwordCommand(
      "svd", "Operate on registers by name.")
    _ = svdCommand.add(DecodeCommand.self, context: self)
    _ = svdCommand.add(InfoCommand.self, context: self)
    _ = svdCommand.add(LoadCommand.self, context: self)
    _ = svdCommand.add(ReadCommand.self, context: self)
    _ = svdCommand.add(WriteCommand.self, context: self)
  }
}

/// Top level plugin library entry point.
///
/// This function serves as lldb's entry point for initializing a plugin. It
/// must use the `C` calling and must match the mangled name of the `C++`
/// function: `bool lldb::PluginInitialize(lldb::SBDebugger debugger)`.
@_cdecl("_ZN4lldb16PluginInitializeENS_10SBDebuggerE")
func pluginInitialize(debugger: UnsafeMutableRawPointer) -> Bool {
  let debugger = debugger.bindMemory(to: lldb.SBDebugger.self, capacity: 1)
  SVD2LLDB.shared = SVD2LLDB(debugger: &debugger.pointee)
  return true
}
