# Installing SVD2LLDB

Install and load the SVD2LLDB plugin.

## Build SVD2LLDB

To build `SVD2LLDB`, follow these steps:

1. Clone the `swift-mmio` repository:

  ```console
  $ git clone git@github.com:apple/swift-mmio.git
  ```

2. Build `SVD2LLDB` with the `FEATURE_SVD2LLDB` feature flag enabled:

  ```console
  $ FEATURE_SVD2LLDB=1 swift build -c release --product SVD2LLDB
  ```

## Loading the Plugin in LLDB

### Manual Loading

You can manually load the `SVD2LLDB` plugin in each LLDB session by using the `plugin load` command in LLDB:

  ```console
  (lldb) plugin load /path/to/swift-mmio/.build/release/libSVD2LLDB.dylib
  ```

### Automatic Loading

To automatically load the `SVD2LLDB` plugin in LLDB sessions, you can set up an LLDB initialization script. Here's how you can do it:

1. Create an LLDB initialization script if you don't have one already. You can name it `.lldbinit` and place it in your home directory.

2. Open the `.lldbinit` file in a text editor.

3. Add the following line to the file to load the `SVD2LLDB` plugin automatically when LLDB starts:

  ```console
  command script import /path/to/swift-mmio/.build/release/libSVD2LLDB.dylib
  ```

4. Save the `.lldbinit` file.

Now, every time you start a new LLDB session, the `SVD2LLDB` plugin will be loaded automatically.

Remember to replace `/path/to/swift-mmio/.build/release/libSVD2LLDB.dylib` with the actual path to the `libSVD2LLDB.dylib` file on your system.

Additionally, you can move `libSVD2LLDB.dylib` to any other location on your system that you prefer. Just make sure to update the path accordingly in your LLDB initialization script or when manually loading the plugin.

> Note: See [LLDB - Configuration Files](https://lldb.llvm.org/man/lldb.html#configuration-files) for more information on `.lldbinit` files.
