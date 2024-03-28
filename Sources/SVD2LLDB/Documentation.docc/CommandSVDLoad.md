# Load

Load an SVD file into the current LLDB session.

## Overview

The `svd load` command allows developers to load a CMSIS SVD file into the current LLDB session. Once loaded, the SVD file provides semantic information about the hardware peripherals and registers of the target device.

The `svd load` command must be run before any other commands.

## Syntax

```console
(lldb) svd load <path-svd-file>
<path-svd-file> - The path to the CMSIS SVD file to be loaded.
```

## Example

Load an SVD file from disk:

```console
(lldb) svd load ~/Downloads/STM32F7x6.svd
Loaded SVD file: STM32F7x6.svd
```
