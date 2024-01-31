//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import CLLDB

extension Array where Element == String {
  init(_ arguments: lldb.SBCommandRawArguments?) {
    self.init()
    guard var arguments = arguments else { return }
    while let argument = arguments.pointee {
      arguments = arguments.successor()
      self.append(String(cString: argument))
    }
  }
}

extension lldb.SBCommand {
  mutating func add(
    command: @escaping (
      _ debugger: inout lldb.SBDebugger,
      _ arguments: [String],
      _ result: inout lldb.SBCommandReturnObject
    ) -> Bool,
    name: StaticString,
    help: StaticString? = nil,
    syntax: StaticString? = nil,
    autoRepeatCommand: StaticString = ""
  ) -> lldb.SBCommand {
    self.AddCommand(
      name.cString,
      lldb.newSBCommand { command(&$0.pointee, .init($1), &$2.pointee) },
      help?.cString,
      syntax?.cString,
      autoRepeatCommand.cString)
  }
}
