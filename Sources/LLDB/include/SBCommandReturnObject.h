//===--------------------------------------------------------------*- h -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLDB_API_SBCOMMANDRETURNOBJECT_H
#define LLDB_API_SBCOMMANDRETURNOBJECT_H

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

#endif // LLDB_API_SBCOMMANDRETURNOBJECT_H
