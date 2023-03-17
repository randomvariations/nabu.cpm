# Compact Flash interface for the NABU Personal Computer

This compact flash design is modeled after the NABU floppy disk controller and designed to connect directly to one of the NABU option slots without the intermediate option adapter.

It consists of logic that implements a board ID (0x50) as well as logic to issue a two cycle write pulse to the compact flash card, in plase of the normal three cycle write issued by the Z80.

It can be used with the 4K rev14id ROM to boot a compact flash card formated with the cpm3 image as found elsewhere in this repository.
