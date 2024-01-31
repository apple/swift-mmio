//===------------------------------------------------------------*- c++ -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if !__has_include(<LLDB/LLDB.h>)

#include "CLLDB.h"
#include <cstdio>

#define ABORT {                                                                \
  fprintf(                                                                     \
    stderr,                                                                    \
    "Invalid use of LLDB stub API '%s'. This indicates "                       \
    "'-F<directory-containing-LLDB.framework>' was not supplied correctly "    \
    "when building SVD2LLDB.\n",                                               \
    __FUNCTION__);                                                             \
  std::abort();                                                                \
}

using namespace lldb;

// MARK: - SBCommand
SBCommand SBCommand::AddCommand(char const*, SBCommandPluginInterface*, char const*, char const*, char const*) ABORT

// MARK: - SBCommandInterpreter
SBCommand SBCommandInterpreter::AddMultiwordCommand(char const*, char const*) ABORT
SBCommandInterpreter::~SBCommandInterpreter() ABORT

// MARK: - SBCommandReturnObject
void SBCommandReturnObject::PutCString(char const*, int) ABORT
void SBCommandReturnObject::AppendWarning(char const*) ABORT
void SBCommandReturnObject::SetError(char const*) ABORT
SBCommandReturnObject::SBCommandReturnObject(SBCommandReturnObject const&) ABORT
SBCommandReturnObject::~SBCommandReturnObject() ABORT

// MARK: - SBDebugger
SBCommandInterpreter SBDebugger::GetCommandInterpreter() ABORT
SBTarget SBDebugger::GetSelectedTarget() ABORT
SBDebugger::SBDebugger(SBDebugger const&) ABORT
SBDebugger::~SBDebugger() ABORT

// MARK: - SBError
const char* SBError::GetCString() const ABORT
bool SBError::IsValid() const ABORT
void SBError::SetError(unsigned int, ErrorType) ABORT
SBError::SBError(SBError const&) ABORT
SBError::SBError() ABORT
SBError::~SBError() ABORT

// MARK: - SBProcess
size_t SBProcess::ReadMemory(addr_t, void*, size_t, lldb::SBError&) ABORT
size_t SBProcess::WriteMemory(addr_t, const void*, size_t, lldb::SBError&) ABORT
SBProcess::~SBProcess() ABORT

// MARK: - SBTarget
SBProcess SBTarget::GetProcess() ABORT
SBTarget::~SBTarget() ABORT

#endif
