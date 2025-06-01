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

#include "Vendor_lldb-types.h"

namespace lldb {

class SBProcess {
public:
  ~SBProcess();

  size_t ReadMemory(addr_t addr, void *buf, size_t size, lldb::SBError &error);

  size_t WriteMemory(addr_t addr, const void *buf, size_t size,
                     lldb::SBError &error);
};

} // namespace lldb
