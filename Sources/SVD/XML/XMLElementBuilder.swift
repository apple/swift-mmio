//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2025 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if canImport(FoundationEssentials) && canImport(FoundationXML)
import FoundationEssentials
import FoundationXML
protocol NSObject {}
#else
import Foundation
#endif

final class XMLElementBuilder: NSObject {
  enum State: ~Copyable {
    case initial
    case parsing(stack: [XMLElement])
    case error
    case complete(root: XMLElement)

    mutating func start(name: String) {
      switch consume self {
      case .initial:
        let node = XMLElement(name: name)
        self = .parsing(stack: [node])
      case .parsing(var stack):
        let node = XMLElement(name: name)
        stack.append(node)
        self = .parsing(stack: stack)
      case .error:
        self = .error
      case .complete:
        self = .error
      }
    }

    mutating func withCurrent(_ body: (inout XMLElement) -> Void) {
      switch consume self {
      case .initial:
        self = .error
      case .parsing(var stack):
        if !stack.isEmpty {
          body(&stack[stack.count - 1])
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

    mutating func end(name: String) {
      switch consume self {
      case .initial:
        self = .error
      case .parsing(var stack):
        if let node = stack.last, node.name == name {
          stack.removeLast()
          if stack.isEmpty {
            self = .complete(root: node)
          } else {
            stack[stack.count - 1].children.append(node)
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
      case .complete(let root):
        self = .error
        return root
      default:
        self = .error
        return nil
      }
    }
  }

  static func build(data: Data) -> XMLElement? {
    let parser = XMLParser(data: data)
    let builder = XMLElementBuilder()
    parser.delegate = builder
    guard parser.parse() else { return nil }
    return builder.state.result()
  }

  var state: State

  #if canImport(FoundationEssentials) && canImport(FoundationXML)
  init() {
    self.state = .initial
  }
  #else
  override init() {
    self.state = .initial
    super.init()
  }
  #endif
}

extension XMLElementBuilder: XMLParserDelegate {
  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String]
  ) {
    self.state.start(name: elementName)
    self.state.withCurrent { node in
      node.attributes = attributeDict
    }
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    self.state.end(name: elementName)
  }

  func parser(_ parser: XMLParser, foundCharacters characters: String) {
    self.state.withCurrent { node in
      node.value = characters
    }
  }

  func parser(_ parser: XMLParser, parseErrorOccurred error: any Error) {
    self.state = .error
  }

  func parser(
    _ parser: XMLParser, validationErrorOccurred error: any Error
  ) {
    self.state = .error
  }
}
