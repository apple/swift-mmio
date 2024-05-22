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

import ArgumentParser
import SVD

struct InfoCommand: SVD2LLDBCommand {
  static let autoRepeat = ""
  static let configuration = CommandConfiguration(
    commandName: "info",
    _superCommandName: "svd",
    abstract: "Retrieve information about hardware items.")

  @Argument(
    help: """
      Key-path to a device, peripheral, cluster, register, or field.
      """)
  var keyPath: [String]

  mutating func run(
    debugger: inout some SVD2LLDBDebugger,
    result: inout some SVD2LLDBResult,
    context: SVD2LLDB
  ) throws -> Bool {
    let device = try context.device.unwrap(or: NoSVDLoadedError())

    // Coalesce requested info key paths into a prefix tree.
    let prefixTree = PrefixTree(element: device.name.lowercased())
    for argument in self.keyPath {
      // Split the argument by "."s into a key path and normalize by lowercasing
      // keys.
      let keyPath = argument.split(separator: ".").map { $0.lowercased() }
      // Note: 0 item key paths are allowed for this command, to allow users to
      // request info about the top level device.
      // Insert the key path into the prefix tree.
      prefixTree.insert(source: argument, sequence: keyPath)
    }

    let info = self.recursiveInfo(
      debugger: &debugger,
      result: &result,
      context: .init(
        prefixTree: prefixTree,
        item: device,
        name: "",
        registerProperties: device.registerProperties,
        address: device.addressOffset))

    // Render the tree to the user, return false if errors occurred.
    return self.render(
      result: &result,
      device: device,
      prefixTree: prefixTree,
      info: info)
  }

  struct Info {
    var name: String
    var properties: [(String, String)]
  }

  struct RecursiveInfoContext {
    var prefixTree: PrefixTree<String>
    var item: any SVDItem
    var name: String
    var registerProperties: SVDRegisterProperties
    var address: UInt64
  }

  mutating func recursiveInfo(
    debugger: inout some SVD2LLDBDebugger,
    result: inout some SVD2LLDBResult,
    context: RecursiveInfoContext
  ) -> [Info] {
    // DFS through the SVD tree using the prefix tree as a needle to trim the
    // search space.
    var queue = [context]
    var info = [Info]()
    while let context = queue.last {
      queue.removeLast()

      if context.prefixTree.source != nil {
        info.append(
          .init(
            name: context.name,
            properties: context.item.info(
              registerProperties: context.registerProperties,
              address: context.address)))
        context.prefixTree.source = nil
      }

      for childItem in context.item.children() {
        // do filtering, must find match in tree to continue search.
        let childPrefixTree = context.prefixTree.children
          .first { $0.element.matches(childItem.name) }
        guard let childPrefixTree = childPrefixTree else { continue }
        let childName =
          if context.name.isEmpty {
            childItem.name
          } else {
            "\(context.name).\(childItem.name)"
          }
        let childRegisterProperties = childItem.registerProperties
          .merging(context.registerProperties)
        let childAddress = childItem.addressOffset + context.address
        queue.append(
          .init(
            prefixTree: childPrefixTree,
            item: childItem,
            name: childName,
            registerProperties: childRegisterProperties,
            address: childAddress))
      }
    }

    return info
  }

  mutating func render(
    result: inout some SVD2LLDBResult,
    device: SVDDevice,
    prefixTree pt: PrefixTree<String>,
    info: [Info]
  ) -> Bool {
    // Walk the info list once to determine the length of the longest property
    // name so we can align the property values.
    var longestPrefix = 0
    for info in info {
      for property in info.properties {
        longestPrefix = max(property.0.count, longestPrefix)
      }
    }

    // Add 4 to the longest prefix to account for prepending "  " and appending
    // ": " to each property name while printing.
    longestPrefix += 4

    var first = true
    for info in info {
      if first {
        first = false
      } else {
        result.output("")
      }
      if info.name != "" {
        result.output("\(info.name):")
      } else {
        result.output("\(device.name):")
      }
      for property in info.properties {
        var description = "  \(property.0):"
        let padding = longestPrefix - description.count
        description.append(repeating: " ", count: padding)
        description.append("\(property.1)")
        result.output(description)
      }
    }

    // Walk the prefix tree looking for sources that have not been set to nil,
    // indicating the matching item in the device tree was not found. Emit an
    // error for each source without a match.
    var unknown = false
    do {
      var queue = [pt]
      while let pt = queue.last {
        // FIXME: use Deque instead of Array as Stack
        queue.removeLast()
        if let source = pt.source {
          result.error("Unknown item “\(source)”.")
          unknown = true
        }
        queue.append(contentsOf: pt.children)
      }
    }

    return !unknown
  }
}
