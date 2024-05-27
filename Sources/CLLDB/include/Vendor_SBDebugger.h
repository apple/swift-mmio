//===--------------------------------------------------------------*- h -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#pragma once

#include "Vendor_SBTarget.h"
#include "Vendor_SBCommandInterpreter.h"

namespace lldb {

class SBCommandInterpreter;

class SBDebugger {
public:
  SBDebugger();

  SBDebugger(const lldb::SBDebugger &rhs);

  ~SBDebugger();

  lldb::SBCommandInterpreter GetCommandInterpreter();

  lldb::SBTarget GetSelectedTarget();
}; // class SBDebugger

} // namespace lldb
