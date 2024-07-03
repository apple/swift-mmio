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

import SwiftUI

enum SVDItemKind {
  case device
  case peripheral
  case cluster
  case register
  case field
}

extension SVDItemKind {
  var imageName: String {
    switch self {
    case .device: "cpu"
    case .peripheral: "rectangle.connected.to.line.below"
    case .cluster: "folder"
    case .register: "gauge.medium"
    case .field: "01.circle"
    }
  }

  var imageColor: Color {
    switch self {
    case .device: .green
    case .peripheral: .mint
    case .cluster: .indigo
    case .register: .purple
    case .field: .orange
    }
  }

  var displayName: String {
    switch self {
    case .device: "Device"
    case .peripheral: "Peripheral"
    case .cluster: "Cluster"
    case .register: "Register"
    case .field: "Field"
    }
  }
}

extension SVDItemKind: Decodable {}

extension SVDItemKind: Encodable {}

extension SVDItemKind: Equatable {}

extension SVDItemKind: Hashable {}
