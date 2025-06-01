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

namespace lldb {

class SBCommandReturnObject {
public:
  SBCommandReturnObject(const lldb::SBCommandReturnObject &rhs);

  ~SBCommandReturnObject();

  void AppendWarning(const char *message);

  void PutCString(const char *string, int len = -1);

  void SetError(const char *error_cstr);
};

} // namespace lldb
