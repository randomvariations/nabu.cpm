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

loadAddr	.EQU	0D000h
numSecs		.EQU	24	; Number of 512 sectors to be loaded


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

;================================================================================================

		.ORG	8000H		; Loader origin.

		CALL	printInline
		.TEXT "CP/M System Transfer by G. Searle 2012"
		.DB CR,LF,0

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

		call	write

		LD	DE,0200H
		LD	HL,(dmaAddr)
		ADD	HL,DE
		LD	(dmaAddr),HL
		LD	A,(secNo)
		INC	A
		LD	(secNo),A

		djnz	processSectors

		CALL	printInline
		.DB CR,LF
		.TEXT "System transfer complete"
		.DB CR,LF,0

		RET				


;================================================================================================
; Write physical sector to host
;================================================================================================

write:
		PUSH 	AF
		PUSH 	BC
		PUSH 	HL


		CALL 	cfWait

		LD 	A,CF_WRITE_SEC
		OUT 	(CF_COMMAND),A

		CALL 	cfWait

		LD 	c,4
		LD 	HL,(dmaAddr)
wr4secs:
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

dmaAddr		.dw	0
secNo		.db	0

	.END
