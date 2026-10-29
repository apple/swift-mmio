//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import ArgumentParser
import CLLDB

extension Array where Element == String {
  init(_ arguments: lldb.SBCommandRawArguments?) {
    self.init()
    guard var arguments = unsafe arguments else { return }
    while let argument = unsafe arguments.pointee {
      unsafe arguments = arguments.successor()
      unsafe self.append(String(cString: argument))
    }
  }
}

extension lldb.SBCommand {
  mutating func add<Command>(
    _ command: Command.Type,
    context: SVD2LLDB
  ) -> lldb.SBCommand
  where Command: SVD2LLDBCommand {
    unsafe self.AddCommand(
      Command.configuration.commandName,
      lldb.newSBCommand {
        unsafe Command.run(
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
