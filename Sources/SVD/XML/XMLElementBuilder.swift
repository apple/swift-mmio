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
  enum State {
    case initial
    case parsing(root: Arc<XMLElement>, stack: [Arc<XMLElement>])
    case error
    case complete(root: Arc<XMLElement>)
  }

  static func build(data: Data) -> Arc<XMLElement>? {
    let parser = XMLParser(data: data)
    let builder = XMLElementBuilder()
    parser.delegate = builder
    guard parser.parse() else { return nil }
    guard case .complete(let root) = builder.state else { return nil }
    return root
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

  func start(name: String) {
    switch self.state {
    case .initial:
      let node = Arc(XMLElement(name: name))
      self.state = .parsing(root: node, stack: [node])
    case .parsing(let root, let stack):
      if let current = stack.last {
        let node = Arc(XMLElement(name: name))
        current.wrapped.children.append(node)
        self.state = .parsing(root: root, stack: stack + [node])
      } else {
        self.state = .error
      }
    case .error:
      self.state = .error
    case .complete:
      self.state = .error
    }
  }

  func current() -> Arc<XMLElement>? {
    switch self.state {
    case .initial:
      self.state = .error
      return nil
    case .parsing(let root, let stack):
      if let node = stack.last {
        self.state = .parsing(root: root, stack: stack)
        return node
      } else {
        self.state = .error
        return nil
      }
    case .error:
      self.state = .error
      return nil
    case .complete:
      self.state = .error
      return nil
    }
  }

  func end(name: String) {
    switch self.state {
    case .initial:
      self.state = .error
    case .parsing(let root, let stack):
      if let node = stack.last, node.wrapped.name == name {
        let stack = stack.dropLast()
        if stack.isEmpty {
          self.state = .complete(root: root)
        } else {
          self.state = .parsing(root: root, stack: Array(stack))
        }
      } else {
        self.state = .error
      }
    case .error:
      self.state = .error
    case .complete:
      self.state = .error
    }
  }
}

extension XMLElementBuilder: XMLParserDelegate {
  func parserDidStartDocument(_ parser: XMLParser) {}
  func parserDidEndDocument(_ parser: XMLParser) {}

  func parser(
    _ parser: XMLParser,
    foundNotationDeclarationWithName name: String,
    publicID: String?,
    systemID: String?
  ) {}

  func parser(
    _ parser: XMLParser,
    foundUnparsedEntityDeclarationWithName name: String,
    publicID: String?,
    systemID: String?,
    notationName: String?
  ) {}

  func parser(
    _ parser: XMLParser,
    foundAttributeDeclarationWithName attributeName: String,
    forElement elementName: String,
    type: String?,
    defaultValue: String?
  ) {}

  func parser(
    _ parser: XMLParser,
    foundElementDeclarationWithName elementName: String,
    model: String
  ) {}

  func parser(
    _ parser: XMLParser,
    foundInternalEntityDeclarationWithName name: String,
    value: String?
  ) {}

  func parser(
    _ parser: XMLParser,
    foundExternalEntityDeclarationWithName name: String,
    publicID: String?,
    systemID: String?
  ) {}

  func parser(
    _ parser: XMLParser,
    didStartElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?,
    attributes attributeDict: [String: String]
  ) {
    self.start(name: elementName)
    if let node = self.current() {
      node.wrapped.attributes = attributeDict
    }
  }

  func parser(
    _ parser: XMLParser,
    didEndElement elementName: String,
    namespaceURI: String?,
    qualifiedName qName: String?
  ) {
    self.end(name: elementName)
  }

  func parser(
    _ parser: XMLParser,
    didStartMappingPrefix prefix: String,
    toURI namespaceURI: String
  ) {}

  func parser(_ parser: XMLParser, didEndMappingPrefix prefix: String) {}

  func parser(_ parser: XMLParser, foundCharacters string: String) {
    if let node = self.current() {
      node.wrapped.value = string
    }
  }

  func parser(
    _ parser: XMLParser,
    foundIgnorableWhitespace whitespaceString: String
  ) {}

  func parser(
    _ parser: XMLParser,
    foundProcessingInstructionWithTarget target: String,
    data: String?
  ) {}

  func parser(_ parser: XMLParser, foundComment comment: String) {}

  func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {}

  func parser(
    _ parser: XMLParser,
    resolveExternalEntityName name: String,
    systemID: String?
  ) -> Data? { nil }

  func parser(_ parser: XMLParser, parseErrorOccurred parseError: any Error) {
    self.state = .error
  }

  func parser(
    _ parser: XMLParser, validationErrorOccurred validationError: any Error
  ) {
    self.state = .error
  }
}
