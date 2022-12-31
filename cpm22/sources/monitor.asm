;==================================================================================
; Contents of this file are copyright Grant Searle
; HEX routines from Joel Owens.
;
; You have permission to use this for NON COMMERCIAL USE ONLY
; If you wish to use it elsewhere, please include an acknowledgement to myself.
;
; http://searle.hostei.com/grant/index.html
;
; eMail: home.micros01@btinternet.com
;
; If the above don't work, please perform an Internet search to see if I have
; updated the web page hosting service.
;
;==================================================================================

;------------------------------------------------------------------------------
;
; Z80 Monitor Rom
;
;------------------------------------------------------------------------------
; General Equates
;------------------------------------------------------------------------------

CR		.EQU	0DH
LF		.EQU	0AH
ESC		.EQU	1BH
CTRLC		.EQU	03H
CLS		.EQU	0CH

; NABU registers

CTRLREG		.EQU	00H

SNDDATA		.EQU	40H
SNDLTCH		.EQU	41H

MIXERIO		.EQU	07H
IOPORTA		.EQU	0EH
IOPORTB		.EQU	0FH

HCCA		.EQU	80H

; CF registers
CF_DATA		.EQU	$C0
CF_FEATURES	.EQU	$C1
CF_ERROR	.EQU	$C1
CF_SECCOUNT	.EQU	$C2
CF_SECTOR	.EQU	$C3
CF_CYL_LOW	.EQU	$C4
CF_CYL_HI	.EQU	$C5
CF_HEAD		.EQU	$C6
CF_STATUS	.EQU	$C7
CF_COMMAND	.EQU	$C7
CF_LBA0		.EQU	$C3
CF_LBA1		.EQU	$C4
CF_LBA2		.EQU	$C5
CF_LBA3		.EQU	$C6

;CF Features
CF_8BIT		.EQU	1
CF_NOCACHE	.EQU	082H
;CF Commands
CF_READ_SEC	.EQU	020H
CF_WRITE_SEC	.EQU	030H
CF_SET_FEAT	.EQU 	0EFH


loadAddr	.EQU	0D000h	; CP/M load address
numSecs		.EQU	24	; Number of 512 sectors to be loaded

		.ORG	$4000
secNo		.ds	1
dmaAddr		.ds	2

stackSpace	.ds	32
STACK   	.EQU    $	; Stack top


;------------------------------------------------------------------------------
;                         START OF MONITOR ROM
;------------------------------------------------------------------------------

MON		.ORG	$0000		; MONITOR ROM RESET VECTOR
;------------------------------------------------------------------------------
; Reset
;------------------------------------------------------------------------------
RST00		DI			;Disable INTerrupts
		JP	INIT		;Initialize Hardware and go
		NOP
		NOP
		NOP
		NOP
;------------------------------------------------------------------------------
; TX a character over RS232 wait for TXDONE first.
;------------------------------------------------------------------------------
RST08		JP	conout
		NOP
		NOP
		NOP
		NOP
		NOP
;------------------------------------------------------------------------------
; RX a character from buffer wait until char ready.
;------------------------------------------------------------------------------
RST10		JP	conin
		NOP
		NOP
		NOP
		NOP
		NOP
;------------------------------------------------------------------------------
; Console input routine
; Use the "primaryIO" flag to determine which input port to monitor.
;------------------------------------------------------------------------------
conin:		LD	A,IOPORTA	; Access Interrupt Mask Register
		OUT	(SNDLTCH),A
		LD	A,080H		; Select HCCA Receive Only
		OUT	(SNDDATA),A
		LD	A,IOPORTB	; Access Interrupt Status Register
		OUT	(SNDLTCH),A
conin1:		IN	A,(SNDDATA)
		AND	0FH
		CP	01H
		JP	NZ,conin1	; Wait until receiver full
		LD	A,IOPORTA	; Access Interrupt Mask Register
		OUT	(SNDLTCH),A
		XOR	A
		OUT	(SNDDATA),A	; Disable all interrupts/status 
		IN	A,(HCCA)
		RET

;------------------------------------------------------------------------------
; Console output routine
; Use the "primaryIO" flag to determine which output port to send a character.
;------------------------------------------------------------------------------
conout:		PUSH	AF
		LD	A,IOPORTA	; Access Interrupt Mask Register
		OUT	(SNDLTCH),A
		LD	A,040H		; Select HCCA Transmit Only
		OUT	(SNDDATA),A
		LD	A,IOPORTB	; Access Interrupt Status Register
		OUT	(SNDLTCH),A
conout1:	IN	A,(SNDDATA)	; Fetch Status information
		AND	0FH
		CP	03H
		JP	NZ,conout1	; Wait until transmitter empty
		LD	A,IOPORTA	; Access Interrupt Mask Register
		OUT	(SNDLTCH),A
		XOR	A
		OUT	(SNDDATA),A	; Disable all interrupts/status 
		POP	AF
		OUT	(HCCA),A
		RET		
;------------------------------------------------------------------------------
; Filtered Character I/O
;------------------------------------------------------------------------------

RDCHR		RST	10H
		CP	LF
		JR	Z,RDCHR		; Ignore LF
		CP	ESC
		JR	NZ,RDCHR1
		LD	A,CTRLC		; Change ESC to CTRL-C
RDCHR1		RET

WRCHR		CP	CR
		JR	Z,WRCRLF	; When CR, write CRLF
		CP	CLS
		JR	Z,WR		; Allow write of "CLS"
		CP	' '		; Don't write out any other control codes
		JR	C,NOWR		; ie. < space
WR		RST	08H
NOWR		RET

WRCRLF		LD	A,CR
		RST	08H
		LD	A,LF
		RST	08H
		LD	A,CR
		RET


;------------------------------------------------------------------------------
; Initialise hardware and start main loop
;------------------------------------------------------------------------------
INIT		LD	SP,STACK		; Set the Stack Pointer
		LD	B,10H			; Disable the Sound Generator
RSTSND:		LD	A,B
		DEC	A
		OUT	(SNDLTCH),A
		XOR	A
		OUT	(SNDDATA),A
		DEC	B
		JP	NZ,RSTSND
		LD	A,MIXERIO		; Configure the A/B ports
		OUT	(SNDLTCH),A
		LD	A,07FH
		OUT	(SNDDATA),A
		LD	A,IOPORTA		; Disable all interrupts
		OUT	(SNDLTCH),A
		LD	A,00H
		OUT	(SNDDATA),A

		CALL TXCRLF	; TXCRLF
		LD   HL,SIGNON	; Print SIGNON message
		CALL PRINT

;------------------------------------------------------------------------------
; Monitor command loop
;------------------------------------------------------------------------------
MAIN  		LD   HL,MAIN	; Save entry point for Monitor	
		PUSH HL		; This is the return address
MAIN0		CALL TXCRLF	; Entry point for Monitor, Normal	
		LD   A,'>'	; Get a ">"	
		RST 08H		; print it

MAIN1		CALL RDCHR	; Get a character from the input port
		CP   ' '	; <spc> or less? 	
		JR   C,MAIN1	; Go back
	
		CP   ':'	; ":"?
		JP   Z,LOAD	; First character of a HEX load

		CALL WRCHR	; Print char on console

		CP   '?'
		JP   Z,HELP

		AND  $5F	; Make character uppercase

		CP   'R'
		JP   Z,RST00
		CP   'G'
		JP   Z,GOTO

		CP   'X'
		JP   Z,CPMLOAD

		LD   A,'?'	; Get a "?"	
		RST 08H		; Print it
		JR   MAIN0
	
;------------------------------------------------------------------------------
; Print string of characters to Serial A until byte=$00, WITH CR, LF
;------------------------------------------------------------------------------
PRINT		LD   A,(HL)	; Get character
		OR   A		; Is it $00 ?
		RET  Z		; Then RETurn on terminator
		RST  08H	; Print it
		INC  HL		; Next Character
		JR   PRINT	; Continue until $00


TXCRLF		LD   A,$0D	; 
		RST  08H	; Print character 
		LD   A,$0A	; 
		RST  08H	; Print character
		RET

;------------------------------------------------------------------------------
; Get a character from the console, must be $20-$7F to be valid (no control characters)
; <Ctrl-c> and <SPACE> breaks with the Zero Flag set
;------------------------------------------------------------------------------	
GETCHR		CALL RDCHR	; RX a Character
		CP   $03	; <ctrl-c> User break?
		RET  Z			
		CP   $20	; <space> or better?
		JR   C,GETCHR	; Do it again until we get something usable
		RET
;------------------------------------------------------------------------------
; Gets two ASCII characters from the console (assuming them to be HEX 0-9 A-F)
; Moves them into B and C, converts them into a byte value in A and updates a
; Checksum value in E
;------------------------------------------------------------------------------
GET2		CALL GETCHR	; Get us a valid character to work with
		LD   B,A	; Load it in B
		CALL GETCHR	; Get us another character
		LD   C,A	; load it in C
		CALL BCTOA	; Convert ASCII to byte
		LD   C,A	; Build the checksum
		LD   A,E
		SUB  C		; The checksum should always equal zero when checked
		LD   E,A	; Save the checksum back where it came from
		LD   A,C	; Retrieve the byte and go back
		RET
;------------------------------------------------------------------------------
; Gets four Hex characters from the console, converts them to values in HL
;------------------------------------------------------------------------------
GETHL		LD   HL,$0000	; Gets xxxx but sets Carry Flag on any Terminator
		CALL ECHO	; RX a Character
		CP   $0D	; <CR>?
		JR   NZ,GETX2	; other key		
SETCY		SCF		; Set Carry Flag
		RET             ; and Return to main program		
;------------------------------------------------------------------------------
; This routine converts last four hex characters (0-9 A-F) user types into a value in HL
; Rotates the old out and replaces with the new until the user hits a terminating character
;------------------------------------------------------------------------------
GETX		LD   HL,$0000	; CLEAR HL
GETX1		CALL ECHO	; RX a character from the console
		CP   $0D	; <CR>
		RET  Z		; quit
		CP   $2C	; <,> can be used to safely quit for multiple entries
		RET  Z		; (Like filling both DE and HL from the user)
GETX2		CP   $03	; Likewise, a <ctrl-C> will terminate clean, too, but
		JR   Z,SETCY	; It also sets the Carry Flag for testing later.
		ADD  HL,HL	; Otherwise, rotate the previous low nibble to high
		ADD  HL,HL	; rather slowly
		ADD  HL,HL	; until we get to the top
		ADD  HL,HL	; and then we can continue on.
		SUB  $30	; Convert ASCII to byte	value
		CP   $0A	; Are we in the 0-9 range?
		JR   C,GETX3	; Then we just need to sub $30, but if it is A-F
		SUB  $07	; We need to take off 7 more to get the value down to
GETX3		AND  $0F	; to the right hex value
		ADD  A,L	; Add the high nibble to the low
		LD   L,A	; Move the byte back to A
		JR   GETX1	; and go back for next character until he terminates
;------------------------------------------------------------------------------
; Convert ASCII characters in B C registers to a byte value in A
;------------------------------------------------------------------------------
BCTOA		LD   A,B	; Move the hi order byte to A
		SUB  $30	; Take it down from Ascii
		CP   $0A	; Are we in the 0-9 range here?
		JR   C,BCTOA1	; If so, get the next nybble
		SUB  $07	; But if A-F, take it down some more
BCTOA1		RLCA		; Rotate the nybble from low to high
		RLCA		; One bit at a time
		RLCA		; Until we
		RLCA		; Get there with it
		LD   B,A	; Save the converted high nybble
		LD   A,C	; Now get the low order byte
		SUB  $30	; Convert it down from Ascii
		CP   $0A	; 0-9 at this point?
		JR   C,BCTOA2	; Good enough then, but
		SUB  $07	; Take off 7 more if it's A-F
BCTOA2		ADD  A,B	; Add in the high order nybble
		RET

;------------------------------------------------------------------------------
; Get a character and echo it back to the user
;------------------------------------------------------------------------------
ECHO		CALL	RDCHR
		CALL	WRCHR
		RET

;------------------------------------------------------------------------------
; GOTO command
;------------------------------------------------------------------------------
GOTO		CALL GETHL		; ENTRY POINT FOR <G>oto addr. Get XXXX from user.
		RET  C			; Return if invalid       	
		PUSH HL
		RET			; Jump to HL address value

;------------------------------------------------------------------------------
; LOAD Intel Hex format file from the console.
; [Intel Hex Format is:
; 1) Colon (Frame 0)
; 2) Record Length Field (Frames 1 and 2)
; 3) Load Address Field (Frames 3,4,5,6)
; 4) Record Type Field (Frames 7 and 8)
; 5) Data Field (Frames 9 to 9+2*(Record Length)-1
; 6) Checksum Field - Sum of all byte values from Record Length to and 
;   including Checksum Field = 0 ]
;------------------------------------------------------------------------------	
LOAD		LD   E,0	; First two Characters is the Record Length Field
		CALL GET2	; Get us two characters into BC, convert it to a byte <A>
		LD   D,A	; Load Record Length count into D
		CALL GET2	; Get next two characters, Memory Load Address <H>
		LD   H,A	; put value in H register.
		CALL GET2	; Get next two characters, Memory Load Address <L>
		LD   L,A	; put value in L register.
		CALL GET2	; Get next two characters, Record Field Type
		CP   $01	; Record Field Type 00 is Data, 01 is End of File
		JR   NZ,LOAD2	; Must be the end of that file
		CALL GET2	; Get next two characters, assemble into byte
		LD   A,E	; Recall the Checksum byte
		AND  A		; Is it Zero?
		JR   Z,LOAD00	; Print footer reached message
		JR   LOADERR	; Checksums don't add up, Error out
		
LOAD2		LD   A,D	; Retrieve line character counter	
		AND  A		; Are we done with this line?
		JR   Z,LOAD3	; Get two more ascii characters, build a byte and checksum
		CALL GET2	; Get next two chars, convert to byte in A, checksum it
		LD   (HL),A	; Move converted byte in A to memory location
		INC  HL		; Increment pointer to next memory location	
		LD   A,'.'	; Print out a "." for every byte loaded
		RST  08H	;
		DEC  D		; Decrement line character counter
		JR   LOAD2	; and keep loading into memory until line is complete
		
LOAD3		CALL GET2	; Get two chars, build byte and checksum
		LD   A,E	; Check the checksum value
		AND  A		; Is it zero?
		RET  Z

LOADERR		LD   HL,CKSUMERR  ; Get "Checksum Error" message
		CALL PRINT	; Print Message from (HL) and terminate the load
		RET

LOAD00  	LD   HL,LDETXT	; Print load complete message
		CALL PRINT
		RET
;------------------------------------------------------------------------------
; Display Help command
;------------------------------------------------------------------------------
HELP   	 	LD   HL,HLPTXT	; Print Help message
		CALL PRINT
		RET
	
;------------------------------------------------------------------------------
; CP/M load command
;------------------------------------------------------------------------------
CPMLOAD

    		LD HL,CPMTXT
		CALL PRINT
		CALL GETCHR
		RET Z	; Cancel if CTRL-C
		AND  $5F ; uppercase
		CP 'Y'
		JP  Z,CPMLOAD2
		RET
CPMTXT
		.BYTE	$0D,$0A
		.TEXT	"Boot CP/M?"
		.BYTE	$00

CPMTXT2
		.BYTE	$0D,$0A
		.TEXT	"Loading CP/M..."
		.BYTE	$0D,$0A,$00

CPMLOAD2
    		LD HL,CPMTXT2
		CALL PRINT


		CALL	cfWait
		LD 	A,CF_8BIT	; Set IDE to be 8bit
		OUT	(CF_FEATURES),A
		LD	A,CF_SET_FEAT
		OUT	(CF_COMMAND),A


		CALL	cfWait
		LD 	A,CF_NOCACHE	; No write cache
		OUT	(CF_FEATURES),A
		LD	A,CF_SET_FEAT
		OUT	(CF_COMMAND),A

		LD	B,numSecs

		LD	A,0
		LD	(secNo),A
		LD	HL,loadAddr
		LD	(dmaAddr),HL
processSectors:

		CALL	cfWait

		LD	A,(secNo)
		OUT 	(CF_LBA0),A
		LD	A,0
		OUT 	(CF_LBA1),A
		OUT 	(CF_LBA2),A
		LD	a,0E0H
		OUT 	(CF_LBA3),A
		LD 	A,1
		OUT 	(CF_SECCOUNT),A

		call	read

		LD	DE,0200H
		LD	HL,(dmaAddr)
		ADD	HL,DE
		LD	(dmaAddr),HL
		LD	A,(secNo)
		INC	A
		LD	(secNo),A

		djnz	processSectors

; Start CP/M using entry at top of BIOS
; The current active console stream ID is pushed onto the stack
; to allow the CBIOS to pick it up
; 0 = SIO A, 1 = SIO B
		XOR	A
		PUSH	AF
		ld	HL,($FFFE)
		jp	(HL)


;------------------------------------------------------------------------------

; Read physical sector from host

read:
		PUSH 	AF
		PUSH 	BC
		PUSH 	HL

		CALL 	cfWait

		LD 	A,CF_READ_SEC
		OUT 	(CF_COMMAND),A

		CALL 	cfWait

		LD 	c,4
		LD 	HL,(dmaAddr)
rd4secs:
		LD 	b,128
rdByte:
		nop
		nop
		in 	A,(CF_DATA)
		LD 	(HL),A
		iNC 	HL
		dec 	b
		JR 	NZ, rdByte
		dec 	c
		JR 	NZ,rd4secs

		POP 	HL
		POP 	BC
		POP 	AF

		RET


; Wait for disk to be ready (busy=0,ready=1)
cfWait:
		PUSH 	AF
cfWait1:
		in 	A,(CF_STATUS)
		AND 	080H
		cp 	080H
		JR	Z,cfWait1
		POP 	AF
		RET

;------------------------------------------------------------------------------

SIGNON	.BYTE	"Z80 SBC Boot ROM 1.1"
		.BYTE	" by G. Searle"
		.BYTE	$0D,$0A
		.BYTE	"Type ? for options"
		.BYTE	$0D,$0A,$00

BASTXT
		.BYTE	$0D,$0A
		.TEXT	"Cold or Warm ?"
		.BYTE	$0D,$0A,$00

CKSUMERR	.BYTE	"Checksum error"
		.BYTE	$0D,$0A,$00

INITTXT  
		.BYTE	$0C
		.TEXT	"Press [SPACE] to activate console"
		.BYTE	$0D,$0A, $00

LDETXT  
		.TEXT	"Load complete."
		.BYTE	$0D,$0A, $00


HLPTXT
		.BYTE	$0D,$0A
		.TEXT	"R           - Reset"
		.BYTE	$0D,$0A
		.TEXT	"X           - Boot CP/M (load $D000-$FFFF from disk)"
		.BYTE	$0D,$0A
		.TEXT	":nnnnnn...  - Load Intel-Hex file record"
		.BYTE	$0D,$0A
        	.BYTE   $00

;------------------------------------------------------------------------------

FINIS		.END	

