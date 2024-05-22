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
import MMIOUtilities
import SVD

struct ReadCommand: SVD2LLDBCommand {
  static let autoRepeat = ""
  static let configuration = CommandConfiguration(
    commandName: "read",
    _superCommandName: "svd",
    abstract: "Read the value of registers")

  @Argument(help: "Key-path to a peripheral, cluster, register, or field.")
  var keyPath: [String]

  @Flag(help: "Always read ignoring side-effects.")
  var force: Bool = false

  mutating func run(
    debugger: inout some SVD2LLDBDebugger,
    result: inout some SVD2LLDBResult,
    context: SVD2LLDB
  ) throws -> Bool {
    let device = try context.device.unwrap(or: NoSVDLoadedError())

    // Coalesce requested reads into a prefix tree.
    var error = false
    let prefixTree = PrefixTree(element: device.name.lowercased())
    for argument in self.keyPath {
      // Split the argument by "."s into a key path and normalize by lowercasing
      // keys.
      let keyPath = argument.split(separator: ".").map { $0.lowercased() }
      // Skip key paths with no items.
      guard !keyPath.isEmpty else {
        result.error("Invalid key path “\(argument)”.")
        error = true
        continue
      }
      // Insert the key path into the prefix tree.
      prefixTree.insert(source: argument, sequence: keyPath)
    }

    // Read the values request by the prefix tree into the register value tree
    // using the device tree to find metadata to determine where/how to read.
    //
    // e.g. needle: prefixTree, haystack: device, result: valueTree.
    let valueTree = ValueTree.container(name: device.name)
    self.recursiveRead(
      debugger: &debugger,
      result: &result,
      context: .init(
        prefixTree: prefixTree,
        item: device,
        valueTree: valueTree,
        readAction: device.readAction,
        address: device.addressOffset,
        size: device.registerProperties.size ?? 0))

    // Render the tree to the user, return false if read errors occurred.
    return self.render(
      result: &result,
      prefixTree: prefixTree,
      valueTree: valueTree) && !error
  }

  struct RecursiveReadContext {
    var prefixTree: PrefixTree<String>?
    var item: any SVDItem
    var valueTree: ValueTree
    var readAction: SVDReadAction?
    var address: UInt64
    var size: UInt64
  }

  mutating func recursiveRead(
    debugger: inout some SVD2LLDBDebugger,
    result: inout some SVD2LLDBResult,
    context: RecursiveReadContext
  ) {
    // DFS through the SVD tree using the prefix tree as a needle to trim the
    // search space.
    var queue = [context]
    while let context = queue.last {
      queue.removeLast()

      // If the current item is a register or field it is readable.
      let isReadable = context.item is SVDRegister || context.item is SVDField
      // Note if the value for this item has already been read. We dont want to
      // read a register multiple times. This can occur if a user requests
      // "Reg" and "Reg.Field".
      let hasBeenRead = context.valueTree.value != nil
      // Read the value if the item is readable and hasn't already been read.
      if isReadable, !hasBeenRead {
        context.valueTree.value = self.read(
          debugger: &debugger,
          readAction: context.readAction,
          address: context.address,
          size: context.size)
      }

      // If the current item is a field we need to extract its value from the
      // parent register and insert a new node into the value tree.
      //
      // Unlike all other SVD items, fields are not inserted into the register
      // value tree during the child recursive descent.
      if let field = context.item as? SVDField {
        let value: ValueTree.Value?
        if case .data(let data, _) = context.valueTree.value {
          // If we successfully read the register this field is found in, slice
          // the field's value from the register's value.
          let range = field.bitRange.range
          value = .data(data[bits: range], UInt64(range.count))
        } else {
          // If the read was skipped or errored, just copy that status from the
          // register's value to the field's value.
          value = context.valueTree.value
        }
        // Add the sliced or copied value from the register and store it in a
        // new value tree node.
        context.valueTree.children.append(
          .init(name: field.name, value: value, children: []))
      }

      // Record if the user specifically requested this node and nil-out the
      // source in the prefix tree if present.
      let userRequested =
        if let prefixTree = context.prefixTree {
          prefixTree.source != nil
        } else {
          false
        }
      context.prefixTree?.source = nil

      for childItem in context.item.children() {
        // The child matching logic is a bit confusing, so lets describe the
        // idea here first.
        //
        // The prefix tree contains all user supplied arguments (key paths),
        // broken up into keys. The terminal keys of the user arguments are
        // marked with `source != nil`. Each of these nodes should be
        // recursively searched down to register nodes (not to fields).
        //
        // A node can be marked as `source != nil` and also have children. This
        // can happen in the case where the user manually specified a key and
        // its parents. e.g. "Reg" (terminal) and "Reg.Field" (terminal).
        //
        // While reading values from the SVD tree its important we nil out
        // `source` for user supplied arguments so we can later report user
        // requested key paths that didn't match anything in the SVD tree.

        var childPrefixTrees = [PrefixTree<String>?]()
        if let prefixTree = context.prefixTree {
          // do filtering, must find match in tree to add node.
          let childPrefixTree = prefixTree.children
            .first { $0.element.matches(childItem.name) }
          if let childPrefixTree = childPrefixTree {
            childPrefixTrees.append(childPrefixTree)
          }
        }

        if userRequested || context.prefixTree == nil,
          !(context.item is SVDRegister)
        {
          // If there is no prefix tree or user requested this node, that means
          // we have entered the read everything phase of the tree walk. Add
          // the child item to the search queue without a prefix tree if the
          // current item is not a register.
          childPrefixTrees.append(nil)
        }

        guard !childPrefixTrees.isEmpty else { continue }

        // Unlike all other SVD items, fields are not inserted into the register
        // value tree during the child recursive descent.
        let childValueTree: ValueTree
        if childItem is SVDField {
          childValueTree = context.valueTree
        } else {
          childValueTree = ValueTree(
            name: childItem.name,
            value: nil,
            children: [])
          context.valueTree.children.append(childValueTree)
        }

        let childReadAction = childItem.readAction ?? context.readAction
        let childAddress = childItem.addressOffset + context.address
        let childSize = childItem.registerProperties.size ?? context.size

        // Add a child item to the queue for each child prefix tree.
        for childPrefixTree in childPrefixTrees {
          queue.append(
            .init(
              prefixTree: childPrefixTree,
              item: childItem,
              valueTree: childValueTree,
              readAction: childReadAction,
              address: childAddress,
              size: childSize))
        }
      }
    }
  }

  mutating func read(
    debugger: inout some SVD2LLDBDebugger,
    readAction: SVDReadAction?,
    address: UInt64,
    size: UInt64
  ) -> ValueTree.Value {
    do {
      // Skip reading registers with side-effects unless forced.
      guard readAction == nil || self.force else { return .skipped }
      // Read the register.
      let value = try debugger.read(address: address, bits: size)
      return .data(value, size)
    } catch {
      return .error
    }
  }

  mutating func render(
    result: inout some SVD2LLDBResult,
    prefixTree pt: PrefixTree<String>,
    valueTree vt: ValueTree
  ) -> Bool {
    // Walk the value tree once to compute the longest prefix so we can align
    // the values in the output. Also note errored or skipped reads.
    var longestPrefix = 0
    var data = false
    var skipped = false
    var error = false
    do {
      var queue = [(vt, 0)]
      while let (vt, prefixCount) = queue.last {
        queue.removeLast()
        longestPrefix = max(vt.name.count + prefixCount, longestPrefix)
        switch vt.value {
        case .data: data = true
        case .skipped: skipped = true
        case .error: error = true
        default: break
        }
        for child in vt.children {
          queue.append((child, prefixCount + 2))
        }
      }
    }

    // Add 2 to the longest prefix to account for appending ": " to each item in
    // tree while printing.
    longestPrefix += 2

    // If the read value tree has any values, walk the tree and print them.
    if data || skipped || error {
      var description = ""
      var queue = [(vt, 0)]
      while let (vt, prefixCount) = queue.last {
        queue.removeLast()
        let trailingPadding = longestPrefix - prefixCount - vt.name.count - 1

        if !description.isEmpty {
          description.append("\n")
        }

        description.append(String(repeating: " ", count: prefixCount))
        description.append(vt.name)
        description.append(":")

        if let value = vt.value {
          description.append(String(repeating: " ", count: trailingPadding))
          description.append("\(value)")
        }

        // FIXME: this should be sorted by address/field offset
        let children = vt.children.sorted { $0.name > $1.name }
        for child in children {
          queue.append((child, prefixCount + 2))
        }
      }
      result.output(description)
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

    // If any registers were skipped while reading, emit a warning.
    if skipped {
      result.warning(
        """
        Skipped registers with side-effects. Use “--force” to read \
        these registers.
        """)
    }

    if error {
      result.error("Failed to read some registers.")
    }

    return !error && !unknown
  }
}
