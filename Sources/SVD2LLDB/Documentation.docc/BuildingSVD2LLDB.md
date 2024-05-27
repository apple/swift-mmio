# Building SVD2LLDB

Build the SVD2LLDB plugin from source.

## Prerequisites

Before you begin, ensure you have a modern Swift toolchain (version 5.9 or newer) and a copy of LLDB.framework with headers. 

Not all operating systems and Swift toolchains include LLDB.framework with headers. 

For example, the Swift.org toolchains for macOS include LLDB.framework with headers, however the Xcode toolchains include LLDB.framework _without_ headers. Additionally, the Swift.org toolchains for Linux and Swift.org Docker containers do not include LLDB.framework at all.

## Build Steps

1. First, clone the `swift-mmio` repository:

  ```console
  $ git clone https://github.com/apple/swift-mmio.git
  $ cd swift-mmio
  ```

2. Locate LLDB.framework and ensure it include headers. For example, a Swift.org macOS toolchain installed globally would be found under `/Library/Developer/Toolchains`.

  ```console
  $ ls /Library/Developer/Toolchains/swift-DEVELOPMENT-SNAPSHOT-2024-05-15-a.xctoolchain/System/Library/PrivateFrameworks
  LLDB.framework
  ```

3. Next, build the SVD2LLDB product with the `SWIFT_MMIO_FEATURE_SVD2LLDB` feature flag enabled and pass the path to the directory containing LLDB.framework as a "framework search path" (-F) flag to both the Swift and C compilers:

  ```console
  $ SWIFT_MMIO_FEATURE_SVD2LLDB=1 \
    swift build \
    --configuration release \
    --product SVD2LLDB \
    -Xswiftc -F$DIRECTORY_CONTAINING_LLDB_FRAMEWORK \
    -Xcc -F$DIRECTORY_CONTAINING_LLDB_FRAMEWORK
  ```

  > Important: The SVD2LLDB plugin may appear to build correctly even if your "framework search path" is incorrect or your copy of LLDB.framework does not include the necessary headers to build SVD2LLDB. If this is the case, you may encounter a run time failure like:
  >
  > ```console
  > (lldb) plugin load .build/debug/libSVD2LLDB.dylib
  > Invalid use of LLDB stub API 'GetCommandInterpreter'. This indicates '-F<directory-containing-LLDB.framework>' was not supplied correctly when building SVD2LLDB.
  > ```

4. Finally, locate the just-built plugin in your build directory:

  ```console
  $ ls $(SWIFT_MMIO_FEATURE_SVD2LLDB=1 swift build --configuration release --show-bin-path)/libSVD2LLDB.dylib
  /path/to/swift-mmio/.build/arm64-apple-macosx/release/libSVD2LLDB.dylib
  ```

5. Optionally, after building you can install libSVD2LLDB.dylib to any location you prefer. For example, the following command installs the plugin to `~/.lldb/libSVD2LLDB.dylib`

  ```console
  $ mkdir -p ~/.lldb
  $ cp $(SWIFT_MMIO_FEATURE_SVD2LLDB=1 swift build --configuration release --show-bin-path)/libSVD2LLDB.dylib ~/.lldb
  ```
