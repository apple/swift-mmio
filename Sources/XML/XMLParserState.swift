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




struct XMLParserState: ~Copyable {
  var current = ""
  var stack: [(
    (
      type: any _XMLParsable.Type,
      partial: UnsafeMutableRawPointer
    )?,
    // FIXME: can this be removed?
    current: String
  )]

  mutating func start(name: UnsafePointer<CChar>) {
    guard !self.stack.isEmpty else { fatalError() }
    let sString = String(cString: name)
    print("start:", sString)

    let (top, _) = self.stack[self.stack.count - 1]

    if let top = top {
      // If theres an element on the top of the stack, check if it wants to
      // parse a child by this name.
      if let parsable = top.type._buildChild(name: name) {
        // if yes, push the child to the top.
        self.stack.append(((parsable, parsable._buildPartial()), sString))
      } else {
        // If no, push an empty element to the top.
        self.stack.append((nil, sString))
      }
    } else {
      // If theres an empty element on the top of the stack, then we're
      // descending down a tree that we dont care about parsing, we can push
      // another empty child.
      self.stack.append((nil, sString))
    }
  }

  mutating func end(name: UnsafePointer<CChar>) {
    guard !self.stack.isEmpty else { fatalError() }
    let sString = String(cString: name)
    print("end:  ", sString)

    let (top, current) = self.stack.removeLast()
    // FIXME: dont crash
    precondition(sString == current)
    
    if let top = top {
      // If theres an element on the top of the stack, try to finalize it into
      // a fully initialized value.
      // FIXME: handle failure
      let value = try! top.type._buildComplete(partial: top.partial)

      if self.stack.isEmpty {
        // If theres a parent of this value, give the child to parent to own.
        fatalError("need to finalize")
      } else {
        // If theres no parent, then we finished parsing the tree.
        print(value)
        fatalError("We're done!")
      }

    } else {
      // If theres an empty element on the top of the stack, then the parent of
      // this element didn't care about parsing it. We can drop the element and
      // move on.
    }

  }
}

//enum XMLParserState: ~Copyable {
//  case initial
//  case parsing(stack: OwnedArray<XMLElement>)
//  case error
//  case complete(root: XMLElement)
//
//  mutating func start(
//    name: consuming String,
//    attributes: consuming OwnedArray<(String, String)>
//  ) {
//    let node = XMLElement(
//      name: name,
//      attributes: attributes,
//      children: OwnedArray())
//    switch consume self {
//    case .initial:
//      var stack = OwnedArray<XMLElement>()
//      stack.push(node)
//      self = .parsing(stack: stack)
//    case .parsing(var stack):
//      stack.push(node)
//      self = .parsing(stack: stack)
//    case .error:
//      self = .error
//    case .complete:
//      self = .error
//    }
//  }
//
//  mutating func characters(text: consuming String) {
//    switch consume self {
//    case .initial:
//      self = .error
//    case .parsing(var stack):
//      if !stack.isEmpty {
//        stack[stack.count - 1].value = text
//        self = .parsing(stack: stack)
//      } else {
//        self = .error
//      }
//    case .error:
//      self = .error
//    case .complete:
//      self = .error
//    }
//  }
//
//  mutating func end(name: consuming String) {
//    switch consume self {
//    case .initial:
//      self = .error
//    case .parsing(var stack):
//      if let node = stack.pop(), node.name == name {
//        if stack.isEmpty {
//          self = .complete(root: node)
//        } else {
//          stack[stack.count - 1].children.push(node)
//          self = .parsing(stack: stack)
//        }
//      } else {
//        self = .error
//      }
//    case .error:
//      self = .error
//    case .complete:
//      self = .error
//    }
//  }
//
//  mutating func result() -> XMLElement? {
//    switch consume self {
//    case .initial:
//      self = .error
//      return nil
//    case .parsing:
//      self = .error
//      return nil
//    case .error:
//      self = .error
//      return nil
//    case .complete(let root):
//      self = .error
//      return root
//    }
//  }
//}
