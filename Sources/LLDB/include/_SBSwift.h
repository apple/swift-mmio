//===--------------------------------------------------------------*- h -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#pragma once

#include "SBCommandInterpreter.h"

namespace lldb {
  typedef char* _Nullable * _Nullable SBCommandRawArguments;
  typedef bool (^ _Nonnull CommandBodyBlock) (
    lldb::SBDebugger&, // Pass by reference to work around runtime crash.
    lldb::SBCommandRawArguments,
    lldb::SBCommandReturnObject&);

  class SBSwiftCommandPluginInterface: public lldb::SBCommandPluginInterface {
  public:
    lldb::CommandBodyBlock body;

    SBSwiftCommandPluginInterface(lldb::CommandBodyBlock body):body(body) { }

    bool
    DoExecute(
      lldb::SBDebugger debugger,
      lldb::SBCommandRawArguments arguments,
      lldb::SBCommandReturnObject &result
    ) override {
      return body(debugger, arguments, result);
    }
  };

  static inline
  lldb::SBCommandPluginInterface* _Nonnull
  newSBCommand(lldb::CommandBodyBlock body) {
    // Create and leak the new command, so the lifetime of command matches that
    // of the plugin.
    return new SBSwiftCommandPluginInterface(body);
  }

  static inline
  const char* _Nullable
  GetCString(lldb::SBError error) {
    return error.GetCString();
  }
}
