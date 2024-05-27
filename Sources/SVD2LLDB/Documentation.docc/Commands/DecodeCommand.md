# Decode

Decode a register value into fields.

## Overview

The `svd decode` command allows you to decode the raw value of a register into fields in a human-readable format.

## Syntax

```
USAGE: svd decode <key-path> [<value>] [--binary] [--read] [--force] [--visual]

ARGUMENTS:
  <key-path>              Key-path to a register.
  <value>                 Existing value to decode.

OPTIONS:
  --binary                Print table values in binary instead of hexadecimal.
  --read                  Read the value from the device instead of an existing
                          value.
  --force                 Always read ignoring side-effects.
  --visual                Include a visual diagram of the fields.
  -h, --help              Show help information.
```

## Example

1. Decode the specified value `0x0123_4567` for register `TIMER0.CR` without reading from the device with a visual diagram:

  ```console
  (lldb) svd decode TIMER0.CR 0x0123_4567 --visual
  TIMER0.CR: 0x0123_4567

                        ╭╴CNTSRC  ╭╴RST
    ╭╴S   ╭╴RELOAD╭╴CAPEDGE  ╭╴MODE
    ┴     ┴─      ┴─    ┴─── ┴──  ┴
  0b00000001001000110100010101100111
        ┬─    ┬─    ┬───    ┬   ┬─ ┬
        ╰╴IDR ╰╴TRGEXT      ╰╴PSC  ╰╴EN
                    ╰╴CAPSRC    ╰╴CNT

  [31:31] S       0x0 (STOP)
  [27:26] IDR     0x0 (KEEP)
  [25:24] RELOAD  0x1 (RELOAD1)
  [21:20] TRGEXT  0x2 (DMA2)
  [17:16] CAPEDGE 0x3
  [15:12] CAPSRC  0x4 (GPIOA_3)
  [11:8]  CNTSRC  0x5 (CAP_SRC_div32)
  [7:7]   PSC     0x0 (Disabled)
  [6:4]   MODE    0x6
  [3:2]   CNT     0x1 (Count_DOWN)
  [1:1]   RST     0x1 (Reset_Timer)
  [0:0]   EN      0x1 (Enable)
  ```

2. Decode the register value of `TIMER0.CR` by reading it from the device:

  ```console
  (lldb) svd decode TIMER0.CR --read
  TIMER0.CR: 0x0123_4567

  [31:31] S       0x0 (STOP)
  [27:26] IDR     0x0 (KEEP)
  [25:24] RELOAD  0x1 (RELOAD1)
  [21:20] TRGEXT  0x2 (DMA2)
  [17:16] CAPEDGE 0x3
  [15:12] CAPSRC  0x4 (GPIOA_3)
  [11:8]  CNTSRC  0x5 (CAP_SRC_div32)
  [7:7]   PSC     0x0 (Disabled)
  [6:4]   MODE    0x6
  [3:2]   CNT     0x1 (Count_DOWN)
  [1:1]   RST     0x1 (Reset_Timer)
  [0:0]   EN      0x1 (Enable)
  ```

3. Decode the register value of `TIMER0.CR` by forcing a read from the device, ignoring side-effects:

  ```console
  (lldb) svd decode TIMER0.CR --read --force
  TIMER0.CR: 0x0123_4567

  ...
  ```
