//===--------------------------------------------------------------*- h -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLDB_API_SBDEBUGGER_H
#define LLDB_API_SBDEBUGGER_H

#include "SBTarget.h"
#include "SBCommandInterpreter.h"

namespace lldb {

class SBCommandInterpreter;

class SBDebugger {
public:
  SBDebugger();

  ~SBDebugger();

  lldb::SBCommandInterpreter GetCommandInterpreter();

  lldb::SBTarget GetSelectedTarget();
}; // class SBDebugger

} // namespace lldb

#endif // LLDB_API_SBDEBUGGER_H
