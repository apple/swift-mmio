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
  /// `space` holds white space that is not yet part of a value.
  case parsing(stack: OwnedArray<XMLElement>, space: XMLByteBuffer)
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
      self = .parsing(stack: stack, space: XMLByteBuffer())
    case .parsing(var stack, var space):
      stack[stack.count - 1].append(space: &space)
      stack.push(node)
      self = .parsing(stack: stack, space: space)
    case .error:
      self = .error
    case .complete:
      self = .error
    }
  }

  mutating func characters(text: UnsafeBufferPointer<UInt8>) {
    switch consume self {
    case .initial:
      self = .error
    case .parsing(var stack, var space):
      let top = stack.count - 1
      if unsafe text.allSatisfy(\.isWhiteSpace) {
        unsafe space.append(contentsOf: text)
      } else if stack[top].value == nil, space.isEmpty {
        stack[top].value = unsafe String(decoding: text, as: UTF8.self)
      } else {
        unsafe space.append(contentsOf: text)
        let value = stack[top].value ?? ""
        stack[top].value = value + space.string()
        space.removeAll()
      }
      self = .parsing(stack: stack, space: space)
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
    case .parsing(var stack, var space):
      if var node = stack.pop(), node.name == name {
        node.append(space: &space)
        if stack.isEmpty {
          self = .complete(root: node)
        } else {
          stack[stack.count - 1].children.push(node)
          self = .parsing(stack: stack, space: space)
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

extension XMLElement {
  fileprivate mutating func append(space: inout XMLByteBuffer) {
    guard !space.isEmpty else { return }
    if let value = self.value {
      self.value = value + space.string()
    }
    space.removeAll()
  }
}
