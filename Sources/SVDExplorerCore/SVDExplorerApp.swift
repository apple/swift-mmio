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
import SVD

public struct SVDExplorerApp: App {
//  @NSApplicationDelegateAdaptor var appDelegate: SVDExplorerAppDelegate

  public var body: some Scene {
    Window("Welcome to SVD Explorer", id: "welcome") {
      WelcomeRootView()
        .frame(height: 440)
//        .toolbar(removing: .title)
//        .toolbarBackground(.hidden, for: .windowToolbar)
    }
    .windowToolbarStyle(.unified)
    .windowStyle(.hiddenTitleBar)
    .windowResizability(.contentSize)

    DocumentGroup(newDocument: SVDDocument()) { file in
      SVDDocumentView(document: file.document)
    }

    Window("About SVD Explorer", id: "about") {
      SVDExplorerAboutView()
        .toolbar(removing: .title)
        .toolbarBackground(.hidden, for: .windowToolbar)
        .containerBackground(.thickMaterial, for: .window)
        .windowMinimizeBehavior(.disabled)
    }
    .windowResizability(.contentSize)
    .restorationBehavior(.disabled)
  }

  public init() {}
}

//final class SVDExplorerAppDelegate: NSObject, NSApplicationDelegate {
//  func applicationDidFinishLaunching(_ notification: Notification) {
//    print(NSDocumentController.shared.recentDocumentURLs)
//  }
//}
