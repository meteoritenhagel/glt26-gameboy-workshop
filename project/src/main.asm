INCLUDE "./include/constants.inc"  ; our constants
INCLUDE "./include/hardware.inc"   ; pre-defined hardware constants


SECTION "Header", ROM0[$100]
	jp EntryPoint
	; Make room for the header, which in total
	; must consist of 150 bytes starting from
	; address $100.
	; The header is later filled using the
	; CLI program rgbfix in the Makefile
	ds $150 - @, 0


SECTION "Entry", ROM0

EntryPoint:
	; Here comes our code!

	call InitStateTitle
.loop
	; Always end your code in an endless loop.
	; Otherwise, the program counter will
	; treat anything it finds as executable code!
	; ("Runaway Code", see also Rule #2 of NASA
	; 10 Rules for Developing Safety Critical Code)
	jr .loop