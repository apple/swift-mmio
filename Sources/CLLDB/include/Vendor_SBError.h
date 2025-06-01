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

#include "Vendor_lldb-enumerations.h"
#include "Vendor_lldb-types.h"

namespace lldb {

class SBError {
public:
  SBError();

  SBError(const lldb::SBError &rhs);

  ~SBError();

  const char* GetCString() const;

  void SetError(uint32_t err, lldb::ErrorType type);

  bool IsValid() const;
};

} // namespace lldb
