# Revision 14 Boot ROM for the NABU Personal Computer using a compact flash adapter

This repository contains a modified 4K rev14 ROM to look for the compact flash card and initialize it in 8-Bit mode using the v2 compact flash adapter.  Once initialized, the first 512 bytes of the card is loaded to 0xC000 and a jump performed to it.

### ROM Changes:

| Address | Original Byte | Modified Byte | Comment |
| ------- | ------------- | ------------- | ------- |
| 0x03C8  | 0xE8  | 0x50  | Change ID to 0x50 |
| 0x0EBB  | 0x20  | 0xE0  | Set LBA Mode vs. CHS |
| 0x0F00  | 0xE8  | 0x50  | Change ID to 0x50 |
| 0x0F41  | 0x3A  | 0xCD  | call |
| 0x0F42  | 0xFD  | 0x5D  | 0x0F5D |
| 0x0F43  | 0xFE  | 0x0F  | to wait for the card |
| 0x0F44  | 0x4F  | 0x00  | NOP |
| 0x0F45  | 0x3E  | 0x00  | NOP |
| 0x0F46  | 0x20  | 0x00  | NOP |
| 0x0F47  | 0xED  | 0x00  | NOP |
| 0x0F48  | 0x79  | 0x00  | NOP |
| 0x0F4A  | 0xF9  | 0xF8  | Write 0x01 to register 1 to select 8-bit mode |
| 0x0F56  | 0x15  | 0xEF  | Execute select features command |

### Context
```
0EB2: F3        di
0EB3: CD F9 0E  call $0EF9              call find compact flash
0EB6: 3A FD FE  ld   a,($FEFD)
0EB9: 4F        ld   c,a
0EBA: 3E E0     ld   a,$E0              LBA mode
0EBC: ED 79     out  (c),a              CF reg 6 = 0xE0

0EF9: 0E CF     ld   c,$CF
0EFB: 06 04     ld   b,$04
0EFD: ED 78     in   a,(c)
0EFF: FE E8     cp   $50                board ID = 0x50
0F01: 28 09     jr   z,$0F0C
0F03: 79        ld   a,c
0F04: C6 10     add  a,$10
0F06: 4F        ld   c,a
0F07: 10 F4     djnz $0EFD
			
0F41: CD 5D 0F  call $0F5D              wait for card to go ready
0F44: 00        nop
0F45: 00 00     nop nop
0F47: 00 00     nop nop
0F49: 3A F8 FE  ld   a,($FEF8)
0F4C: 4F        ld   c,a
0F4D: 3E 01     ld   a,$01              8-bit mode feature
0F4F: ED 79     out  (c),a              CF reg 1 = 0x01
0F51: 3A FF FE  ld   a,($FEFF)
0F54: 4F        ld   c,a
0F55: 3E EF     ld   a,$EF              Set features command
0F57: ED 79     out  (c),a              CF Reg 7 = 0xEF
0F58: CD 5D 0F  call $0F5D
0F5C: C9        ret

0F5D: C5        push bc
0F5E: 3A FE FE  ld   a,($FEFE)
0F61: 4F        ld   c,a
0F62: ED 78     in   a,(c)              check card status
0F64: CB 7F     bit  7,a                busy?
0F66: 20 FA     jr   nz,$0F62
0F68: CB 47     bit  0,a                error?
0F6A: 20 02     jr   nz,$0F6E
0F6C: C1        pop  bc
0F6D: C9          ret
```

