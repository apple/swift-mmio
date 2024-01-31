//===--------------------------------------------------------------*- h -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#pragma once

#include "Vendor_SBDebugger.h"
#include "Vendor_SBCommandReturnObject.h"

namespace lldb {

class SBCommand;

class SBCommandPluginInterface;

class SBCommandInterpreter {
public:
  ~SBCommandInterpreter();

  lldb::SBCommand AddMultiwordCommand(const char *name, const char *help);
};

class SBCommandPluginInterface {
public:
  virtual ~SBCommandPluginInterface() = default;

  virtual bool DoExecute(lldb::SBDebugger /*debugger*/, char ** /*command*/,
                         lldb::SBCommandReturnObject& /*result*/) {
    return false;
  }
};

class SBCommand {
public:
  lldb::SBCommand AddCommand(const char *name,
                             lldb::SBCommandPluginInterface *impl,
                             const char *help, const char *syntax,
                             const char *auto_repeat_command);
};

} // namespace lldb
