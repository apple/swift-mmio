# Load

Load an SVD file into your LLDB session.

## Overview

The `svd load` command allows you to load a CMSIS SVD file into the current LLDB session. Once loaded, the SVD file provides semantic information about the hardware peripherals and registers of the target device, powering the other `svd ...` commands.

> Important: The `svd load` command must be run before any other commands.

## Syntax

```console
USAGE: svd load <path>

ARGUMENTS:
  <path>                  Path to SVD file.

OPTIONS:
  -h, --help              Show help information.
```

## Example

Load an SVD file from disk:

```console
(lldb) svd load ~/Downloads/STM32F7x6.svd
Loaded SVD file: “STM32F7x6.svd”
```
