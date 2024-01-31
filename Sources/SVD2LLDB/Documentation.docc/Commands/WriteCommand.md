# Write

Write a new value to a register.

## Overview

The `svd write` command allows you to modify register values by name. It supports writing an entire register or just a field. By default, it skips writing registers with side-effects to avoid unintentional modifications, and includes an optional flag to force writing, ignoring side-effects.

> Important: `svd write` is missing support for writing fields and tracking side effects.

## Syntax

```console
Write a new value to a register.

USAGE: svd write <key-path> <value> [--force]

ARGUMENTS:
  <key-path>              Key-path to a register or field.
  <value>                 Value to write.

OPTIONS:
  --force                 Always write or modify ignoring side-effects.
  -h, --help              Show help information.
```

## Examples

1. Write the value of a register without side-effects:

  ```console
  (lldb) svd write GPIOA.MODER 0x2800_0001
  Wrote: 0x2800_0001
  ```

2. Write the value of a field without side-effects:

  ```console
  (lldb) svd write GPIOA.MODER.OSPEED 0x1
  Wrote: 0x2800_0001
  ```

3. Write the value of a register with side-effects without using "--force":

  ```console
  (lldb) svd write USART1.ISCR 0x1000_0000
  error: Skipped write of register with side-effects. Use "--force" to write this register.
  ```

4. Write the value of a register with side-effects using "--force":

  ```console
  (lldb) svd write USART1.ISCR 0x1000_0000 --force
  Wrote: 0x1000_0000
  ```
