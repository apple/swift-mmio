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
  var stack: OwnedArray<(any _XMLParsable.Type, UnsafeMutableRawPointer)?>

  var x: String {
    var x = ""
    for index in self.stack.indices {
      if x != "" { x += "/" }
      x += d(self.stack[index])
    }
    return x
  }

  func d(_ x: (any _XMLParsable.Type, UnsafeMutableRawPointer)?) -> String {
    if let (type, partial) = x {
      let low = UInt8(truncatingIfNeeded: UInt(bitPattern: partial))
      return "\(type)(\(String(low, radix: 16)))"
    } else {
      return "nil"
    }
  }

  mutating func start(name: UnsafePointer<CChar>) {
    guard !self.stack.isEmpty else { fatalError("goto fail") }
    let sString = String(cString: name)
    print("\n-------\n\(self.x) -> \(sString)")

    if let (type, _) = self.stack[self.stack.count - 1] {
      // FIXME: check if current partial wants more children for "name" error
      // early if not.

      // If theres an element on the top of the stack, check if it wants to
      // parse a child by this name.
      if let childType = type._buildChild(name: name) {
        let childPartial = childType._buildPartial()
        print("\t-> \(d((childType, childPartial)))")
        // if yes, push the child to the top.
        self.stack.push((childType, childPartial))
      } else {
        print("\t-> nil")
        // If no, push an empty element to the top.
        self.stack.push(nil)
      }
    } else {
      print("\t-> nil")
      // If theres an empty element on the top of the stack, then we're
      // descending down a tree that we dont care about parsing, we can push
      // another empty child.
      self.stack.push(nil)
    }
  }

  mutating func end(name: UnsafePointer<CChar>) {
    let sString = String(cString: name)
    print("\n-------\n\(self.x) <- \(sString)")

    guard let top = self.stack.pop() else { fatalError("goto fail") }

    if let (_type, partial) = top {
      // If theres an element on the top of the stack, try to finalize it into
      // a fully initialized value.
      // FIXME: handle failure
      let value = try! _type._buildComplete(partial: partial)
      print("\t<- \(type(of: value))")
      // There must be a parent to end, error if none.
      guard !self.stack.isEmpty else { fatalError("goto fail") }

      // Give the initialized child to parent to assign to the proper member.
      let topIndex = self.stack.count - 1
      guard let (parentType, parentPartial) = self.stack[topIndex] else {
        preconditionFailure("Invalid empty element under valid element")
      }
      parentType._buildAny(partial: parentPartial, name: name, value: value)

    } else {
      // If theres an empty element on the top of the stack, then the parent of
      // this element didn't care about parsing it. We can drop the element and
      // move on.
      print("\t<- nil")
    }
  }

  mutating func complete<Value>(as _: Value.Type = Value.self) -> Value? {
    guard self.stack.count == 1 else { fatalError("goto fail") }
    guard let (type, partial) = self.stack[0] else { fatalError("goto fail") }
    let value = try! type._buildComplete(partial: partial)
    guard let value = value as? Value else { fatalError("goto fail") }
    return value
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
