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

struct SVD2SwiftPluginConfiguration {
  var peripherals: [String]
  var accessLevel: String?
  var indentationWidth: Int?
  var indentUsingTabs: Bool?
  var namespaceUnderDevice: Bool?
  var instanceMemberPeripherals: Bool?
  var overrideDeviceName: String?
}

extension SVD2SwiftPluginConfiguration {
  enum CodingKeys: String, CodingKey {
    case peripherals = "peripherals"
    case accessLevel = "access-level"
    case indentationWidth = "indentation-width"
    case indentUsingTabs = "indent-using-tabs"
    case namespaceUnderDevice = "namespace-under-device"
    case instanceMemberPeripherals = "instance-member-peripherals"
    case overrideDeviceName = "device-name"
  }
}

extension SVD2SwiftPluginConfiguration: Decodable {}
