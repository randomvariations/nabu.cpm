# Simple Compact Flash interface for the NABU Personal Computer

The compact flash card interface can be created by connecting the data lines (D0-D7 = J9 pins 16-23) and lower three address lines (A0-A2 = J9 pins 6-8) to a compact flash card adapter.  The chip select (J9 pin 5) can be connected to the card's card select line.  The option slot read (J9 pin 12) and write (J9 pin 11) lines are gated by the IO request (J9 pin 13) using two OR gates such as those in a 74HCT32.  The output from these forms the IOR and IOW signals.  A small (less than 100ohm) resistor should be placed in series with the output of each gate in order to help with signal integrity[^1], and then routed to the IOR and IOW signals on the compact flash card.

A working prototype has been shared at [OSH Park](https://oshpark.com/shared_projects/MVhAVmNW)

![schematic](https://github.com/randomvariations/nabu.cpm/blob/main/cf_adapter/images/cf_schematic.png?raw=true)

For those using the floppy disk controller and wishing to connect the adapter to it directly, this schematic can be used:

![schematic](https://github.com/randomvariations/nabu.cpm/blob/main/cf_adapter/images/cf_schematic_fdc.png?raw=true)


[^1]:  Signal integrity has been discovered to be an issue on many of the compact flash and IDE interface designs used by hobbiests on their projects.  The Ultra DMA ATA specification recommends the usage of series termination resistors on most of the IO lines, with values as either 22 ohms or 33 ohms for signals originating from the host or signals that are bidirection respectively.  On my breadboard prototype, I found that I needed to increase the read/write resistors to 100 ohms.  I did not need other resistors for use with the single card that I tested.  A more robust design would include not only series termination resistors as per the specification, but also include buffering in order to ensure that the resistors are placed as close to the source as possible.
