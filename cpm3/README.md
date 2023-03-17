# CP/M 3.0 for the NABU Personal Computer using a simple compact flash adapter

This repository contains files consisting of a hard drive image that can be written to the compact flash card, and a bare copy of cpm3.sys with updates to use LBA mode for the hard drive interface which can be copied to a floppy disk in order to access the compact flash card.  Additional files are available to create a new drive image from a blank image.

### Creating a bootable disk image

This uses cpmtools to create a file that is bootable when written to a compact flash card.

```
dd if=/dev/zero of=<image_name>.raw bs=512 count=19584

mkfs.cpm -f nabu-hddf <image_name>.raw

mkfs.cpm -f nabu-hdd -b boot_block.bin -b cpmldr.bin <image_name>.raw

cpmcp -f nabu-hdd <image_name>.raw cpm3-ide.sys 0:cpm3.sys

cpmcp -f nabu-hdd <image_name>.raw ccp.com 0:ccp.com
```

The first two mkfs.cpm commands create the F and E partitions, with the second adding the boot block and loader to the begining of the disk.  The cpmcp instructions copy the required system files to the disk.

The definitions required for the two drives are:

```
diskdef nabu-hdd
    seclen 512
    tracks 1224
    sectrk 16
    blocksize 4096
    maxdir 1024
    boottrk 4
    os 3
end

# Nabu hard disk 2nd partition F:
diskdef nabu-hddf
    seclen 512
    tracks 1224
    sectrk 16
    blocksize 4096
    maxdir 256
    boottrk 980
    os 3
end
```

The chdman command from MAME can be used to convert this to a chd file usable in MAME with an emulated compact flash adapter.

```
chdman createhd -f -chs 306,4,16 -c none -i <image_name>.raw -o <image_name>.chd
```

### Block 0 Loader Changes:
(Addresses on disk, add 0xC000 for in memory)

| Address | Original Byte | Modified Byte | Comment |
| ------- | ------------- | ------------- | ------- |
| 0x000C  | 0xE8  | 0x50  | Change ID to 0x50 |
| 0x006C  | 0x20  | 0xE0  | Set LBA Mode vs CHS |

### CPMLDR Changes:
(Addresses on disk, subtract 0x100 for in memory)

| Address | Original Byte | Modified Byte | Comment |
| ------- | ------------- | ------------- | ------- |
| 0x0D02  | 0x20  | 0xE0  | Set LBA Mode vs. CHS |
| 0x0D09  | 0x15  | 0x10  | MAME wants 0x10 vs. 0x15 |
| 0x0D17  | 0x75  | 0x70  | MAME wants 0x70 vs. 0x75 |

The largest change is to convert from CHS to LBA by multiplying the cylinder by 64 (shift left 6 times) and adding the sector address.

```
0x0D3F:
29              add     hl,hl
29              add     hl,hl
29              add     hl,hl
29              add     hl,hl
29              add     hl,hl
29              add     hl,hl
dd 46 0e        ld	b,(ix+$0e)	- sector high
dd 4e 0d        ld	c,(ix+$0d)	- sector low
09              add     hl,bc

0x0D4C:
3e 01           ld	a,$01
dd 4e 03        ld	c,(ix+$03)	- c = sector count
ed 79           out     (c),a           - Sector Count = 1

0x0D53:
7d              ld	a,l             - a = LBA low byte
dd 4e 04        ld	c,(ix+$04)	- c = sector number (low byte)
ed 79           out     (c),a           - LBA Low Byte

0x0D59:
7c              ld	a,h             - a = LBA mid byte
dd 4e 05        ld	c,(ix+$05)	- c = cylinder low (mid byte)
ed 79           out     (c),a           - LBA Mid Byte

0x0D5F:
af              xor     a               - a = 0
dd 4e 06        ld	c,(ix+$06)	- c = cylinder high
ed 79           out     (c),a           - LBA High Byte = 0

0xD64:
3e e0           ld	a,$e0
dd 4e 07        ld	c,(ix+$07)	- c = Register 6 (Card/Head)
ed 79           out     (c),a           - LBA mode

0xD6B:
c9              ret
```

### CPM3.SYS Changes:
(Addresses in memory)

| Address | Original Byte | Modified Byte | Comment |
| ------- | ------------- | ------------- | ------- |
| 0xED26  | 0x20  | 0xE0  | Set LBA Mode vs. CHS |
| 0xEDF5  | 0x20  | 0xE0  | Set LBA Mode vs. CHS |
| 0xEDFE  | 0x15  | 0x10  | MAME wants 0x10 vs. 0x15 |
| 0xEE11  | 0x20  | 0xE0  | Set LBA Mode vs. CHS |
| 0xEE61  | 0xE8  | 0x50  | Change ID to 0x50 |

Again, the largest change is to convert from CHS to LBA by multiplying the cylinder by 64 (shift left 6 times) and adding the sector address.

```
0xEC93:
29              add     hl,hl
29              add     hl,hl
29              add     hl,hl
29              add     hl,hl
29              add     hl,hl
29              add     hl,hl

0xEC99:
dd 46 06        ld	b,(ix+$06)	- sector high
dd 4e 05        ld	c,(ix+$05)	- sector low
09              add     hl,bc

0xECA0:
3e 01           ld	a,$01
dd 4e 14        ld	c,(ix+$14)	- c = sector count
ed 79           out     (c),a           - Sector Count = 1

0xECA7:
7d              ld	a,l             - a = LBA low byte
dd 4e 15        ld	c,(ix+$15)	- c = sector number (low byte)
ed 79           out     (c),a           - LBA Low Byte

0xECAD:
7c              ld	a,h             - a = LBA mid byte
dd 4e 16        ld	c,(ix+$16)	- c = cylinder low (mid byte)
ed 79           out     (c),a           - LBA Mid Byte

0xECB3:
af              xor     a               - a = 0
dd 4e 17        ld	c,(ix+$17)	- c = cylinder high
ed 79           out     (c),a           - LBA High Byte = 0

0xECB9:
3e e0           ld	a,$e0
dd 4e 18        ld	c,(ix+$18)	- c = Register 6 (Card/Head)
ed 79           out     (c),a           - LBA mode

0xECC0:
00 00 00 00     nop nop nop nop
00 00 00 00     nop nop nop nop
00 00 00 00     nop nop nop nop
00              nop
```

### Credits

The boot block and loader were written by brijohn:

https://forum.vcfed.org/index.php?threads/nabu-pc-emulation-under-mame.1241092/post-1290800

https://forum.vcfed.org/index.php?threads/nabu-pc-emulation-under-mame.1241092/post-1291507

The hard disk image used was compiled by guidol from brijohn's original image:

https://forum.vcfed.org/index.php?threads/nabu-pc-emulation-under-mame.1241092/post-1291523

cpmtools disk defitions are available from here:

https://forum.vcfed.org/index.php?threads/nabu-pc-emulation-under-mame.1241092/post-1291635

https://forum.vcfed.org/index.php?threads/nabu-pc-emulation-under-mame.1241092/post-1291683

