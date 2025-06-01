//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
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
