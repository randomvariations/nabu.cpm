# CP/M for the NABU Personal Computer using a serial terminal

This code is based on the code developed by Grant Searle as linked on http://searle.x10host.com/cpm/index.html.

It is designed for a 32MB compact flash card installed in option slot 0 and a USB->TTL serial converter connected to the transmit (pin 25) and receive (pin 21) connections on the installed [TR1863](https://github.com/randomvariations/nabu.cpm/blob/main/images/tr1863.png).  These pins should be lifted and connected to the RX and TX pines of the serial converter.

While the port is clocked around 3% slower than the normal 115200 rate, it appears that most converters are accurate enough to still work.  If using minicom (or another terminal) that can insert a small delay between characters, it may be helpful to use a 1-2ms delay.

The monitor.hex file can be burned to a 4K or 8K EPROM and used to replace the existing EPROM installed in the system.

Once the system has started, the form32.hex file can be uploaded and run (g8000) to format the compact flash card.

After formatting, the CPM22.HEX and cbios32.hex files can be uploaded, followed by putsys.hex.  Once complete, executing g8000 will place CP/M on the compact flash card.

Executing the X command followed by a Y for yes will then load and execute CP/M from the compact flash card.

The compact flash card interface can be created by connecting the data lines (D0-D7 = J9 pins 16-23) and lower three address lines (A0-A2 = J9 pins 6-8) to a compact flash card adapter.  The chip select (J9 pin 5) can be connected to the card's card select line.  The option slot read (J9 pin 12) and write (J9 pin 11) lines are gated by the IO request (J9 pin 13) using two OR gates such as those in a 74LS32.  The output from these forms the IOR and IOW signals.  A small (100ohm) resistor should be placed in series with the output of each gate in order to help with signal integrity[^1], and then routed to the IOR and IOW signals on the compact flash card.

![schematic](https://github.com/randomvariations/nabu.cpm/blob/main/images/schematic.png?raw=true)

```
Z80 CP/M BIOS 1.0 by G. Searle 2007-13

CP/M 2.2 Copyright 1979 (c) by Digital Research

A>dir
A: ZORK1    DAT : ZORK1    COM
A>zork1
ZORK I: The Great Underground Empire
Copyright 1982 by Infocom, Inc.
All rights reserved.
ZORK is a trademark of Infocom, Inc.
Release 25 / Serial number 000000

West of House
You are standing in an open field west of a white house, with
a boarded front door.
There is a small mailbox here.

>open mailbox
Opening the mailbox reveals a leaflet.

>take leaflet
Taken.
                                                                                
>read leaflet                                                                   
WELCOME TO ZORK                                                                 
     ZORK is a game of adventure, danger, and low cunning. In                   
it you will explore some of the most amazing territory ever                     
seen by mortals.                                                                
                                                                                
    No computer should be without one!                                          
                                                                                
    Copyright 1982 by Infocom, Inc.                                             
          All rights reserved.                                                  
  ZORK is a trademark of Infocom, Inc.                                          
                                                                                
                                                                                
>

```

[^1]:  Signal integrity has been discovered to be an issue on many of the compact flash and IDE interface designs used by hobbiests on their projects.  The Ultra DMA ATA specification recommends the usage of series termination resistors on most of the IO lines, with values as either 22 ohms or 33 ohms for signals originating from the host or signals that are bidirection respectively.  On my breadboard prototype, I found that I needed to increase the read/write resistors to 100 ohms.  I did not need other resistors for use with the single card that I tested.  A more robust design would include not only series termination resistors as per the specification, but also include buffering in order to ensure that the resistors are placed as close to the source as possible.
