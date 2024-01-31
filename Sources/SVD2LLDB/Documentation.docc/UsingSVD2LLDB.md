# Using SVD2LLDB

Use the SVD2LLDB plugin in a debug session.

## Load SVD2LLDB in LLDB

Before using the SVD2LLDB plugin you must first build it, see <doc:BuildingSVD2LLDB> for details.

### Manual Loading

You can manually load the SVD2LLDB plugin into your LLDB session by using the `plugin load` command in the LLDB console:∂

  ```console
  (lldb) plugin load /path/to/libSVD2LLDB.dylib
  ```

### Automatic Loading

To automatically load the SVD2LLDB plugin in LLDB sessions, you can set up an LLDB initialization script.

1. Create an LLDB initialization script if you don't have one already. Name it `.lldbinit` and place it in your home directory.

  ```console
  $ touch ~/.lldbinit
  ```

2. Open the `.lldbinit` file in a text editor and add the following line to the file to load the SVD2LLDB plugin automatically when LLDB starts:

  ```console
  plugin load /path/to/libSVD2LLDB.dylib
  ```

Now, every time you start a new LLDB session, the SVD2LLDB plugin will be loaded automatically.

Remember to replace `/path/to/libSVD2LLDB.dylib` with the actual path to the `libSVD2LLDB.dylib` file on your system.

> Note: See [LLDB - Configuration Files](https://lldb.llvm.org/man/lldb.html#configuration-files) for more information on `.lldbinit` files.
