;==================================================================================
; Contents of this file are copyright Grant Searle
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

numDrives	.EQU	3		; Not including A:


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

LF		.EQU	0AH		;line feed
FF		.EQU	0CH		;form feed
CR		.EQU	0DH		;carriage RETurn

;====================================================================================

		.ORG	8000H		; Format program origin.


		CALL	printInline
		.TEXT "CP/M Formatter by G. Searle 2012"
		.DB CR,LF,0

		LD	A,'A'
		LD	(drvName),A

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


; There are 512 directory entries per disk, 4 DIR entries per sector
; So 128 x 128 byte sectors are to be initialised
; The drive uses 512 byte sectors, so 32 x 512 byte sectors per disk
; require initialisation

;Drive 0 (A:) is slightly different due to reserved track, so DIR sector starts at 32
		LD	A,(drvName)
		RST	08H		; Print drive letter
		INC	A
		LD	(drvName),A

		LD	A,$20
		LD	(secNo),A

processSectorA:
		CALL	cfWait

		LD	A,(secNo)
		OUT 	(CF_LBA0),A
		LD	A,0
		OUT 	(CF_LBA1),A
		LD	A,0
		OUT 	(CF_LBA2),A
		LD	a,$E0
		OUT 	(CF_LBA3),A
		LD 	A,1
		OUT 	(CF_SECCOUNT),A

		call	writeDir

		LD	A,(secNo)
		INC	A
		LD	(secNo),A
		CP	$40
		JR	NZ, processSectorA



;Drive 1 onwards (B: etc) don't have reserved tracks, so sector starts at 0

		LD 	DE,$0040  ; HL increment
		LD 	HL,$0040  ; H = LBA2, L=LBA1, initialise for drive 1 (B:)

		LD	B,numDrives

processDirs:

		LD	A,(drvName)
		RST	08H		; Print drive letter
		INC	A
		LD	(drvName),A

		LD	A,0
		LD	(secNo),A

processSector:
		CALL	cfWait

		LD	A,(secNo)
		OUT 	(CF_LBA0),A
		LD	A,L
		OUT 	(CF_LBA1),A
		LD	A,H
		OUT 	(CF_LBA2),A
		LD	a,0E0H
		OUT 	(CF_LBA3),A
		LD 	A,1
		OUT 	(CF_SECCOUNT),A

		call	writeDir

		LD	A,(secNo)
		INC	A
		LD	(secNo),A
		CP	$20
		JR	NZ, processSector

		ADD	HL,DE

		DEC	B
		JR	NZ,processDirs

		CALL	printInline
		.DB CR,LF
		.TEXT "Formatting complete"
		.DB CR,LF,0

		RET				

;================================================================================================
; Write physical sector to host
;================================================================================================

writeDir:
		PUSH 	AF
		PUSH 	BC
		PUSH 	HL

		CALL 	cfWait

		LD 	A,CF_WRITE_SEC
		OUT 	(CF_COMMAND),A

		CALL 	cfWait

		LD 	c,4
wr4secs:
		LD 	HL,dirData
		LD 	b,128
wrByte:		LD 	A,(HL)
		nop
		nop
		OUT 	(CF_DATA),A
		iNC 	HL
		dec 	b
		JR 	NZ, wrByte

		dec 	c
		JR 	NZ,wr4secs

		POP 	HL
		POP 	BC
		POP 	AF

		RET

;================================================================================================
; Utilities
;================================================================================================

printInline:
		EX 	(SP),HL 	; PUSH HL and put RET ADDress into HL
		PUSH 	AF
		PUSH 	BC
nextILChar:	LD 	A,(HL)
		CP	0
		JR	Z,endOfPrint
		RST 	08H
		INC 	HL
		JR	nextILChar
endOfPrint:	INC 	HL 		; Get past "null" terminator
		POP 	BC
		POP 	AF
		EX 	(SP),HL 	; PUSH new RET ADDress on stack and restore HL
		RET

;================================================================================================
; Wait for disk to be ready (busy=0,ready=1)
;================================================================================================
cfWait:
		PUSH 	AF
cfWait1:
		in 	A,(CF_STATUS)
		AND 	080H
		cp 	080H
		JR	Z,cfWait1
		POP 	AF
		RET

secNo		.db	0
drvName		.db	0


; Directory data for 1 x 128 byte sector
dirData:
		.DB $E5,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$00,$00
		.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

		.DB $E5,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$00,$00
		.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

		.DB $E5,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$00,$00
		.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

		.DB $E5,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$00,$00,$00,$00
		.DB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

		.END
	
