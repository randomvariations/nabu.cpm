# CP/M for the NABU Personal Computer using a serial terminal

This code is based on the code developed by Grant Searle as linked on http://searle.x10host.com/cpm/index.html.

It is designed for a 32MB compact flash card installed in option slot 0 and a USB->TTL serial converter connected to the transmit (pin 25) and receive (pin 21) connections on the installed [TR1863](https://github.com/randomvariations/nabu.cpm/blob/main/images/tr1863.png).  These pins should be lifted and connected to the RX and TX pines of the serial converter.

While the port is clocked around 3% slower than the normal 115200 rate, it appears that most converters are accurate enough to still work.  If using minicom (or another terminal) that can insert a small delay between characters, it may be helpful to use a 1-2ms delay.

The monitor.hex file can be burned to a 4K or 8K EPROM and used to replace the existing EPROM installed in the system.

Once the system has started, the form32.hex file can be uploaded and run (g8000) to format the compact flash card.

After formatting, the CPM22.HEX and cbios32.hex files can be uploaded, followed by putsys.hex.  Once complete, executing g8000 will place CP/M on the compact flash card.

Executing the X command followed by a Y for yes will then load and execute CP/M from the compact flash card.

The compact flash card interface can be created by connecting the data lines (D0-D7 = J9 pins 16-23) and lower three address lines (A0-A2 = J9 pins 6-8) to a compact flash card adapter.  The chip select (J9 pin 5) can be connected to the card's card select line.  The option slot read (J9 pin 12) and write (J9 pin 11) lines are gated by the IO request (J9 pin 13) using two OR gates such as those in a 74LS32.  The output from these forms the IOR and IOW signals.  A small (100ohm) resistor should be placed in series with the output in order to help with signal integrity, and then routed to the IOR and IOW signals on the compact flash card.

![schematic](https://github.com/randomvariations/nabu.cpm/blob/main/images/schematic.png?raw=true)
