# Using SVD2LLDB

Use the SVD2LLDB plugin in a debug session.

## Build Steps

Before using the SVD2LLDB plugin you must build it.

1. First, clone the `swift-mmio` repository:

  ```console
  $ git clone https://github.com/apple/swift-mmio.git
  $ cd swift-mmio
  ```

2. Next, build the SVD2LLDB product with the `SWIFT_MMIO_FEATURE_SVD2LLDB` feature flag enabled.

  ```console
  $ SWIFT_MMIO_FEATURE_SVD2LLDB=1 \
    swift build \
    --configuration release \
    --product SVD2LLDB \
  ```

3. Finally, locate the just-built plugin in your build directory:

  ```console
  $ ls $(SWIFT_MMIO_FEATURE_SVD2LLDB=1 swift build --configuration release --show-bin-path)/libSVD2LLDB.dylib
  /path/to/swift-mmio/.build/arm64-apple-macosx/release/libSVD2LLDB.dylib
  ```

4. Optionally, after building you can install libSVD2LLDB.dylib to any location you prefer. For example, the following command installs the plugin to `~/.lldb/libSVD2LLDB.dylib`

  ```console
  $ mkdir -p ~/.lldb
  $ cp $(SWIFT_MMIO_FEATURE_SVD2LLDB=1 swift build --configuration release --show-bin-path)/libSVD2LLDB.dylib ~/.lldb
  ```
 
## Load SVD2LLDB in LLDB

You can manually load the SVD2LLDB plugin into your LLDB session by using the `plugin load` command in the LLDB console:

  ```console
  (lldb) plugin load /path/to/libSVD2LLDB.dylib
  ```

To automatically load the SVD2LLDB plugin in LLDB sessions, add the `plugin load` command to your LLDB initialization script.

1. Create an LLDB initialization script if you don't have one already. Name it `.lldbinit` and place it in your home directory.

  ```console
  $ touch ~/.lldbinit
  ```

2. Open the `.lldbinit` file in a text editor and add the `plugin load` command.

  ```console
  plugin load /path/to/libSVD2LLDB.dylib
  ```

Now, every time you start a new LLDB session, the SVD2LLDB plugin will be loaded automatically.

Remember to replace `/path/to/libSVD2LLDB.dylib` with the actual path to the `libSVD2LLDB.dylib` file on your system.

> Note: See [LLDB - Configuration Files](https://lldb.llvm.org/man/lldb.html#configuration-files) for more information on `.lldbinit` files.
