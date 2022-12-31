
all: monitor.hex form32.hex putsys.hex cbios32.hex

monitor.hex: monitor.asm
	dosbox -c "TASM.EXE -t80 monitor.asm"
	mv MONITOR.OBJ ../binaries/monitor.hex

form32.hex: form32.asm
	dosbox -c "TASM.EXE -t80 form32.asm"
	mv FORM32.OBJ ../binaries/form32.hex

putsys.hex: putsys.asm
	dosbox -c "TASM.EXE -t80 putsys.asm"
	mv PUTSYS.OBJ ../binaries/putsys.hex

cbios32.hex: cbios32.asm
	dosbox -c "TASM.EXE -t80 cbios32.asm"
	mv CBIOS32.OBJ ../binaries/cbios32.hex

