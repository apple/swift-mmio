//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import MMIOUtilities

enum XMLElementBuilderState: ~Copyable {
  case initial
  case parsing(stack: OwnedArray<XMLElement>)
  case error
  case complete(root: XMLElement)

  mutating func start(
    name: consuming String,
    attributes: consuming OwnedArray<(String, String)>
  ) {
    let node = XMLElement(
      name: name,
      attributes: attributes,
      children: OwnedArray())
    switch consume self {
    case .initial:
      var stack = OwnedArray<XMLElement>()
      stack.push(node)
      self = .parsing(stack: stack)
    case .parsing(var stack):
      stack.push(node)
      self = .parsing(stack: stack)
    case .error:
      self = .error
    case .complete:
      self = .error
    }
  }

  mutating func characters(text: consuming String) {
    switch consume self {
    case .initial:
      self = .error
    case .parsing(var stack):
      if !stack.isEmpty {
        stack[stack.count - 1].value = text
        self = .parsing(stack: stack)
      } else {
        self = .error
      }
    case .error:
      self = .error
    case .complete:
      self = .error
    }
  }

  mutating func end(name: consuming String) {
    switch consume self {
    case .initial:
      self = .error
    case .parsing(var stack):
      if let node = stack.pop(), node.name == name {
        if stack.isEmpty {
          self = .complete(root: node)
        } else {
          stack[stack.count - 1].children.push(node)
          self = .parsing(stack: stack)
        }
      } else {
        self = .error
      }
    case .error:
      self = .error
    case .complete:
      self = .error
    }
  }

  mutating func result() -> XMLElement? {
    switch consume self {
    case .initial:
      self = .error
      return nil
    case .parsing:
      self = .error
      return nil
    case .error:
      self = .error
      return nil
    case .complete(let root):
      self = .error
      return root
    }
  }
}

