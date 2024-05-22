//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
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
  mutating func add<Command>(
    _ command: Command.Type,
    context: SVD2LLDB
  ) -> lldb.SBCommand
  where Command: SVD2LLDBCommand {
    self.AddCommand(
      Command.configuration.commandName,
      lldb.newSBCommand {
        Command.run(
          arguments: .init($1),
          debugger: &$0.pointee,
          result: &$2.pointee,
          context: context)
      },
      Command.configuration.abstract,
      Command.usageString(),
      Command.autoRepeat)
  }
}
