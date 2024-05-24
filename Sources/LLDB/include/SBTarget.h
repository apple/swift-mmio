//===--------------------------------------------------------------*- h -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLDB_API_SBTARGET_H
#define LLDB_API_SBTARGET_H

namespace lldb {

class SBProcess;

class SBTarget {
public:
  ~SBTarget();

  lldb::SBProcess GetProcess();
};

} // namespace lldb

#endif // LLDB_API_SBTARGET_H
