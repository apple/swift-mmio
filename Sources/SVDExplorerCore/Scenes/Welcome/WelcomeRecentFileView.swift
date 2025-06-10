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

#if os(macOS)
import SwiftUI

struct WelcomeRecentFileView: View {
  var file: URL

  var fileIcon: NSImage {
    NSWorkspace.shared.icon(forFile: self.file.path(percentEncoded: false))
  }
  var fileName: String { self.file.lastPathComponent }
  var parentDirectory: String {
    self.file
      .deletingLastPathComponent()
      .path(percentEncoded: false)
      .abbreviatingWithTildeInPath()
  }

  var body: some View {
    HStack(spacing: 8) {
      Image(nsImage: self.fileIcon)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 32, height: 32)

      VStack(alignment: .leading) {
        Text(self.fileName)
          .foregroundColor(.primary)
          .font(.body)
          .fontWeight(.semibold)
          .lineLimit(1)

        Text(self.parentDirectory)
          .foregroundColor(.secondary)
          .font(.subheadline)
          .lineLimit(1)
          .truncationMode(.head)
      }
    }
    .frame(height: 36)
    .contentShape(Rectangle())
  }
}

#Preview {
  WelcomeRecentFileView(file: URL(fileURLWithPath: #filePath))
}
#endif
