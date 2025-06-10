//===----------------------------------------------------------*- swift -*-===//
//
// This source file is part of the Swift MMIO open source project
//
// Copyright (c) 2024 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

#if os(macOS)
import AppKit
import SwiftUI

extension Image {
  @MainActor
  static var applicationIcon: Image {
    Image(nsImage: NSApp.applicationIconImage)
  }
}
#else
import UIKit
import SwiftUI

extension Image {
  @MainActor
  static var applicationIcon: Image {
    let iconsDictionary = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any]
    let primaryIconsDictionary = iconsDictionary?["CFBundlePrimaryIcon"] as? [String: Any]
    let iconFiles = primaryIconsDictionary?["CFBundleIconFiles"] as? [String]
    let iconName = iconFiles?.last ?? ""

    return Image(uiImage: UIImage(named: iconName) ?? UIImage())
  }
}
#endif
