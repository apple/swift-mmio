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

// This file is a TBD style list of symbols which SVD2LLDB requires from
// LLDB.framework. We use the contents of this file to create linker flags to
// which allow these symbols to be undefined when linking. They ultimately are
// provided by the lldb process into which SVD2LLDB is loaded.
//
// This strategy does not work for arm64e, we will deal with that problem later.
//
// This file intentionally has the extension cpp so Swift Package Manager
// considers "LLDB" to be a C++ target.
//
// Important: Updating this file will not trigger SwiftPM to re-determine the
// linker flags the LLDB target so be sure to modify Package.swift after
// modifying this file so the linker flags are actually updated.

/*

// MARK: - SBCommand
// SBCommand::AddCommand(char const*, SBCommandPluginInterface*, char const*, char const*, char const*)
__ZN4lldb9SBCommand10AddCommandEPKcPNS_24SBCommandPluginInterfaceES2_S2_S2_

// MARK: - SBCommandInterpreter
// SBCommandInterpreter::AddMultiwordCommand(char const*, char const*)
__ZN4lldb20SBCommandInterpreter19AddMultiwordCommandEPKcS2_
// SBCommandInterpreter::~SBCommandInterpreter()
__ZN4lldb20SBCommandInterpreterD1Ev

// MARK: - SBCommandReturnObject
// SBCommandReturnObject::PutCString(char const*, int)
__ZN4lldb21SBCommandReturnObject10PutCStringEPKci
// SBCommandReturnObject::AppendWarning(char const*)
__ZN4lldb21SBCommandReturnObject13AppendWarningEPKc
// SBCommandReturnObject::SetError(char const*)
__ZN4lldb21SBCommandReturnObject8SetErrorEPKc
// SBCommandReturnObject::SBCommandReturnObject(SBCommandReturnObject const&)
__ZN4lldb21SBCommandReturnObjectC1ERKS0_
// SBCommandReturnObject::~SBCommandReturnObject()
__ZN4lldb21SBCommandReturnObjectD1Ev

// MARK: - SBDebugger
// SBDebugger::GetSelectedTarget()
__ZN4lldb10SBDebugger17GetSelectedTargetEv
// SBDebugger::GetCommandInterpreter()
__ZN4lldb10SBDebugger21GetCommandInterpreterEv
// SBDebugger::SBDebugger(SBDebugger const&)
__ZN4lldb10SBDebuggerC1ERKS0_
// SBDebugger::~SBDebugger()
__ZN4lldb10SBDebuggerD1Ev

// MARK: - SBError
// SBError::GetCString() const
__ZNK4lldb7SBError10GetCStringEv
// SBError::IsValid() const
__ZNK4lldb7SBError7IsValidEv
// SBError::SetError(unsigned int, ErrorType)
__ZN4lldb7SBError8SetErrorEjNS_9ErrorTypeE
// SBError::SBError(SBError const&)
__ZN4lldb7SBErrorC1ERKS0_
// SBError::SBError()
__ZN4lldb7SBErrorC1Ev
// SBError::~SBError()
__ZN4lldb7SBErrorD1Ev

// MARK: - SBProcess
// SBProcess::ReadMemory(unsigned long long, void*, unsigned long, SBError&)
__ZN4lldb9SBProcess10ReadMemoryEyPvmRNS_7SBErrorE
// SBProcess::WriteMemory(unsigned long long, void const*, unsigned long, SBError&)
__ZN4lldb9SBProcess11WriteMemoryEyPKvmRNS_7SBErrorE
// SBProcess::~SBProcess()
__ZN4lldb9SBProcessD1Ev

// MARK: - SBTarget
// SBTarget::GetProcess()
__ZN4lldb8SBTarget10GetProcessEv
// SBTarget::~SBTarget()
__ZN4lldb8SBTargetD1Ev

*/
