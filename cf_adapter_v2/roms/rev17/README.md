# Revision 17 Boot ROM for the NABU Personal Computer using a compact flash adapter

This repository contains a modified 4K rev17 ROM to look for the compact flash card and initialize it in 8-Bit mode using the v2 compact flash adapter.  Once initialized, the first 512 bytes of the card is loaded to 0xC000 and a jump performed to it.

### ROM Changes:

| Address | Original Byte | Modified Byte | Comment |
| ------- | ------------- | ------------- | ------- |
| 0x03C0  | 0xE8  | 0x50  | Change ID to 0x50 |
| 0x0EDF  | 0x20  | 0xE0  | Set LBA Mode vs. CHS |
| 0x0F24  | 0xE8  | 0x50  | Change ID to 0x50 |
| 0x0F65  | 0x3A  | 0xCD  | call |
| 0x0F66  | 0xFD  | 0x81  | 0x0F81 |
| 0x0F67  | 0xFE  | 0x0F  | to wait for the card |
| 0x0F68  | 0x4F  | 0x00  | NOP |
| 0x0F69  | 0x3E  | 0x00  | NOP |
| 0x0F6A  | 0x20  | 0x00  | NOP |
| 0x0F6B  | 0xED  | 0x00  | NOP |
| 0x0F6C  | 0x79  | 0x00  | NOP |
| 0x0F6E  | 0xF9  | 0xF8  | Write 0x01 to register 1 to select 8-bit mode |
| 0x0F7A  | 0x15  | 0xEF  | Execute select features command |

### Context
```
0ED6: F3        di
0ED7: CD 1D 0F  call $0F1D              call find compact flash
0EDA: 3A FD FE  ld   a,($FEFD)
0EDD: 4F        ld   c,a
0EDE: 3E 20     ld   a,$E0              LBA mode
0EE0: ED 79     out  (c),a              CF reg 6 = 0xE0

0F1D: 0E CF     ld   c,$CF
0F1F: 06 04     ld   b,$04
0F21: ED 78     in   a,(c)
0F23: FE E8     cp   $50                board ID = 0x50
0F25: 28 09     jr   z,$0F30
0F27: 79        ld   a,c
0F28: C6 10     add  a,$10
0F2A: 4F        ld   c,a
0F2B: 10 F4     djnz $0F21

0F65: CD 5D 0F  call $0F81              wait for card to go ready
0F68: 00        nop
0F69: 00 00     nop nop
0F6B: 00 00     nop nop
0F6D: 3A F8 FE  ld   a,($FEF8)
0F70: 4F        ld   c,a
0F71: 3E 01     ld   a,$01              8-bit mode feature
0F73: ED 79     out  (c),a              CF Reg 1 = 0x01
0F75: 3A FF FE  ld   a,($FEFF)
0F78: 4F        ld   c,a
0F79: 3E 15     ld   a,$EF              Set features command
0F7B: ED 79     out  (c),a              CF Reg 7 = 0xEF
0F7D: CD 81 0F  call $0F81
0F80: C9        ret

0F81: C5        push bc
0F82: 3A FE FE  ld   a,($FEFE)
0F85: 4F        ld   c,a
0F86: ED 78     in   a,(c)              check card status
0F88: CB 7F     bit  7,a                busy?
0F8A: 20 FA     jr   nz,$0F86
0F8C: CB 47     bit  0,a                error?
0F8E: 20 02     jr   nz,$0F92
0F90: C1        pop  bc
0F91: C9        ret
```

