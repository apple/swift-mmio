//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

import Foundation

extension String {
  var quotingReservedWords: String {
    switch self {
    case "__consuming": "`__consuming`"
    case "__owned": "`__owned`"
    case "__setter_access": "`__setter_access`"
    case "__shared": "`__shared`"
    case "_alignment": "`_alignment`"
    case "_backDeploy": "`_backDeploy`"
    case "_borrow": "`_borrow`"
    case "_borrowing": "`_borrowing`"
    case "_BridgeObject": "`_BridgeObject`"
    case "_cdecl": "`_cdecl`"
    case "_Class": "`_Class`"
    case "_compilerInitialized": "`_compilerInitialized`"
    case "_const": "`_const`"
    case "_consuming": "`_consuming`"
    case "_documentation": "`_documentation`"
    case "_dynamicReplacement": "`_dynamicReplacement`"
    case "_effects": "`_effects`"
    case "_expose": "`_expose`"
    case "_forward": "`_forward`"
    case "_implements": "`_implements`"
    case "_linear": "`_linear`"
    case "_local": "`_local`"
    case "_modify": "`_modify`"
    case "_move": "`_move`"
    case "_mutating": "`_mutating`"
    case "_NativeClass": "`_NativeClass`"
    case "_NativeRefCountedObject": "`_NativeRefCountedObject`"
    case "_noMetadata": "`_noMetadata`"
    case "_nonSendable": "`_nonSendable`"
    case "_objcImplementation": "`_objcImplementation`"
    case "_objcRuntimeName": "`_objcRuntimeName`"
    case "_opaqueReturnTypeOf": "`_opaqueReturnTypeOf`"
    case "_optimize": "`_optimize`"
    case "_originallyDefinedIn": "`_originallyDefinedIn`"
    case "_PackageDescription": "`_PackageDescription`"
    case "_private": "`_private`"
    case "_projectedValueProperty": "`_projectedValueProperty`"
    case "_read": "`_read`"
    case "_RefCountedObject": "`_RefCountedObject`"
    case "_semantics": "`_semantics`"
    case "_specialize": "`_specialize`"
    case "_spi": "`_spi`"
    case "_spi_available": "`_spi_available`"
    case "_swift_native_objc_runtime_base": "`_swift_native_objc_runtime_base`"
    case "_Trivial": "`_Trivial`"
    case "_TrivialAtMost": "`_TrivialAtMost`"
    case "_TrivialStride": "`_TrivialStride`"
    case "_typeEraser": "`_typeEraser`"
    case "_unavailableFromAsync": "`_unavailableFromAsync`"
    case "_underlyingVersion": "`_underlyingVersion`"
    case "_UnknownLayout": "`_UnknownLayout`"
    case "_version": "`_version`"
    case "accesses": "`accesses`"
    case "actor": "`actor`"
    case "addressWithNativeOwner": "`addressWithNativeOwner`"
    case "addressWithOwner": "`addressWithOwner`"
    case "any": "`any`"
    case "Any": "`Any`"
    case "as": "`as`"
    case "assignment": "`assignment`"
    case "associatedtype": "`associatedtype`"
    case "associativity": "`associativity`"
    case "async": "`async`"
    case "attached": "`attached`"
    case "autoclosure": "`autoclosure`"
    case "availability": "`availability`"
    case "available": "`available`"
    case "await": "`await`"
    case "backDeployed": "`backDeployed`"
    case "before": "`before`"
    case "block": "`block`"
    case "borrowing": "`borrowing`"
    case "break": "`break`"
    case "canImport": "`canImport`"
    case "case": "`case`"
    case "catch": "`catch`"
    case "class": "`class`"
    case "compiler": "`compiler`"
    case "consume": "`consume`"
    case "copy": "`copy`"
    case "consuming": "`consuming`"
    case "continue": "`continue`"
    case "convenience": "`convenience`"
    case "convention": "`convention`"
    case "cType": "`cType`"
    case "default": "`default`"
    case "defer": "`defer`"
    case "deinit": "`deinit`"
    case "deprecated": "`deprecated`"
    case "derivative": "`derivative`"
    case "didSet": "`didSet`"
    case "differentiable": "`differentiable`"
    case "distributed": "`distributed`"
    case "do": "`do`"
    case "dynamic": "`dynamic`"
    case "each": "`each`"
    case "else": "`else`"
    case "enum": "`enum`"
    case "escaping": "`escaping`"
    case "exclusivity": "`exclusivity`"
    case "exported": "`exported`"
    case "extension": "`extension`"
    case "fallthrough": "`fallthrough`"
    case "false": "`false`"
    case "file": "`file`"
    case "fileprivate": "`fileprivate`"
    case "final": "`final`"
    case "for": "`for`"
    case "discard": "`discard`"
    case "forward": "`forward`"
    case "func": "`func`"
    case "get": "`get`"
    case "guard": "`guard`"
    case "higherThan": "`higherThan`"
    case "if": "`if`"
    case "import": "`import`"
    case "in": "`in`"
    case "indirect": "`indirect`"
    case "infix": "`infix`"
    case "init": "`init`"
    case "initializes": "`initializes`"
    case "inline": "`inline`"
    case "inout": "`inout`"
    case "internal": "`internal`"
    case "introduced": "`introduced`"
    case "is": "`is`"
    case "isolated": "`isolated`"
    case "kind": "`kind`"
    case "lazy": "`lazy`"
    case "left": "`left`"
    case "let": "`let`"
    case "line": "`line`"
    case "linear": "`linear`"
    case "lowerThan": "`lowerThan`"
    case "macro": "`macro`"
    case "message": "`message`"
    case "metadata": "`metadata`"
    case "module": "`module`"
    case "mutableAddressWithNativeOwner": "`mutableAddressWithNativeOwner`"
    case "mutableAddressWithOwner": "`mutableAddressWithOwner`"
    case "mutating": "`mutating`"
    case "nil": "`nil`"
    case "noasync": "`noasync`"
    case "noDerivative": "`noDerivative`"
    case "noescape": "`noescape`"
    case "none": "`none`"
    case "nonisolated": "`nonisolated`"
    case "nonmutating": "`nonmutating`"
    case "objc": "`objc`"
    case "obsoleted": "`obsoleted`"
    case "of": "`of`"
    case "open": "`open`"
    case "operator": "`operator`"
    case "optional": "`optional`"
    case "override": "`override`"
    case "package": "`package`"
    case "postfix": "`postfix`"
    case "precedencegroup": "`precedencegroup`"
    case "prefix": "`prefix`"
    case "private": "`private`"
    case "Protocol": "`Protocol`"
    case "protocol": "`protocol`"
    case "public": "`public`"
    case "reasync": "`reasync`"
    case "renamed": "`renamed`"
    case "repeat": "`repeat`"
    case "required": "`required`"
    case "_resultDependsOn": "`_resultDependsOn`"
    case "_resultDependsOnSelf": "`_resultDependsOnSelf`"
    case "rethrows": "`rethrows`"
    case "retroactive": "`retroactive`"
    case "return": "`return`"
    case "reverse": "`reverse`"
    case "right": "`right`"
    case "safe": "`safe`"
    case "self": "`self`"
    case "Self": "`Self`"
    case "Sendable": "`Sendable`"
    case "set": "`set`"
    case "some": "`some`"
    case "sourceFile": "`sourceFile`"
    case "spi": "`spi`"
    case "spiModule": "`spiModule`"
    case "static": "`static`"
    case "struct": "`struct`"
    case "subscript": "`subscript`"
    case "super": "`super`"
    case "swift": "`swift`"
    case "switch": "`switch`"
    case "target": "`target`"
    case "then": "`then`"
    case "throw": "`throw`"
    case "throws": "`throws`"
    case "transpose": "`transpose`"
    case "true": "`true`"
    case "try": "`try`"
    case "Type": "`Type`"
    case "typealias": "`typealias`"
    case "unavailable": "`unavailable`"
    case "unchecked": "`unchecked`"
    case "unowned": "`unowned`"
    case "unsafe": "`unsafe`"
    case "unsafeAddress": "`unsafeAddress`"
    case "unsafeMutableAddress": "`unsafeMutableAddress`"
    case "var": "`var`"
    case "visibility": "`visibility`"
    case "weak": "`weak`"
    case "where": "`where`"
    case "while": "`while`"
    case "willSet": "`willSet`"
    case "witness_method": "`witness_method`"
    case "wrt": "`wrt`"
    case "yield": "`yield`"
    default: self
    }
  }
}

extension String.StringInterpolation {
  mutating func appendInterpolation(_ value: AccessLevel?) {
    if let value = value {
      self.appendLiteral("\(value) ")
    }
  }

  mutating func appendInterpolation(hex value: some FixedWidthInteger) {
    self.appendLiteral("0x")
    self.appendLiteral(String(value, radix: 16))
  }

  mutating func appendInterpolation(comment: String?) {
    guard let comment = comment else { return }
    let components = comment.components(separatedBy: .newlines)
    for (index, line) in components.enumerated() {
      self.appendLiteral("///")
      if !line.isEmpty {
        self.appendLiteral(" ")
        self.appendLiteral(line.trimmingCharacters(in: .whitespaces))
      }
      if index != components.index(before: components.endIndex) {
        self.appendLiteral("\n")
      }
    }
  }

  mutating func appendInterpolation(identifier: String) {
    let name = identifier.replacingOccurrences(of: "-", with: "_").quotingReservedWords
    self.appendLiteral(name)
  }
}
