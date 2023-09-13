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

import SwiftSyntax

protocol HasIntroducerKeyword {
  var introducerKeyword: TokenSyntax { get }
}

extension ActorDeclSyntax: HasIntroducerKeyword {
  var introducerKeyword: TokenSyntax { self.actorKeyword }
}
extension ClassDeclSyntax: HasIntroducerKeyword {
  var introducerKeyword: TokenSyntax { self.classKeyword }
}
extension EnumDeclSyntax: HasIntroducerKeyword {
  var introducerKeyword: TokenSyntax { self.enumKeyword }
}
extension ExtensionDeclSyntax: HasIntroducerKeyword {
  var introducerKeyword: TokenSyntax { self.extensionKeyword }
}
extension ProtocolDeclSyntax: HasIntroducerKeyword {
  var introducerKeyword: TokenSyntax { self.protocolKeyword }
}
extension StructDeclSyntax: HasIntroducerKeyword {
  var introducerKeyword: TokenSyntax { self.structKeyword }
}
