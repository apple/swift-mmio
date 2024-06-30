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
    case .device: "d.square.fill"
    case .peripheral: "p.square.fill"
    case .cluster: "c.square.fill"
    case .register: "r.square.fill"
    case .field: "f.square.fill"
    }
  }

  var imageColor: Color {
    switch self {
    case .device: .orange
    case .peripheral: .purple
    case .cluster: .cyan
    case .register: .green
    case .field: .mint
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
