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

struct WelcomeRecentFilesListView: View {
  @State var selection: Set<URL> = []
  @State var recentFiles: [URL] = []

  @Environment(\.openURL) var openURL
  @Environment(\.dismissWindow) var dismissWindow

  var body: some View {
    List(self.recentFiles, id: \.self, selection: self.$selection) { file in
      WelcomeRecentFileView(file: file)
    }
    .listStyle(.sidebar)
    .contextMenu(forSelectionType: URL.self) { files in
      if files.isEmpty {
        EmptyView()
      } else {
        Button("Show in Finder") {
          NSWorkspace.shared.activateFileViewerSelecting(Array(files))
        }
      }
    } primaryAction: { files in
      for file in files {
        openURL(file)
      }
      self.dismissWindow()
    }
    .onAppear {
      self.recentFiles = NSDocumentController.shared.recentDocumentURLs
    }
    .onReceive(NSApp.publisher(for: \.keyWindow)) { _ in
      // FIXME: this should be KVO based
      self.recentFiles = NSDocumentController.shared.recentDocumentURLs
    }
    .overlay {
      if self.recentFiles.isEmpty {
        VStack {
          Spacer()
          Text("No Recent Files")
            .font(.body)
            .foregroundColor(.secondary)
          Spacer()
        }
      }
    }
  }
}

#Preview {
  WelcomeRecentFilesListView()
}

