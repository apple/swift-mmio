# Decode

Decode raw register values into semantic fields.

## Overview

The `svd decode` command allows developers to decode the raw value of a register into semantic fields defined in an SVD file. This command is particularly useful during debugging sessions to interpret register values in a human-readable format.

## Syntax

```console
(lldb) svd decode <key-path> <value>
<key-path> - A key-path to a register
<value>    - The value to decode
```

## Example

Decode the raw value `0x0123_4567` for register `TIMER0.CR` into semantic fields:

```console
(lldb) svd decode TIMER0.CR 0x0123_4567
TIMER0.CR: 0x0123_4567

                      ╭╴CNTSRC  ╭╴RST
  ╭╴S   ╭╴RELOAD╭╴CAPEDGE  ╭╴MODE
  ┴     ┴─      ┴─    ┴─── ┴──  ┴ 
0b00000001001000110100010101100111
      ┬─    ┬     ─┬──    ┬   ─┬ ┬
      ╰╴IDR ╰╴TRGEXT      ╰╴PSC╰╴CNT
                  ╰╴CAPSRC      ╰╴EN

  [0:0] EN:      0b1     true
  [1:1] RST:     0b1     true
  [2:3] CNT:     0b01    1
  [4:6] MODE:    0b110   6
  [7:7] PSC:     0b0     false
 [8:11] CNTSRC:  0b0101  divide-by-32
[12:15] CAPSRC:  0b0100  HSI
[16:17] CAPEDGE: 0b11    pos-edge 
[20:21] TRGEXT:  0b1     true
[24:25] RELOAD:  0b00    0
[26:27] IDR:     0b00    0
[31:31] S:       0b0     false
```
