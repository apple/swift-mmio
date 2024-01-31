//===--------------------------------------------------------------*- h -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
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
