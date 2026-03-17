INCLUDE "./include/hardware.inc"


SECTION "Variables", WRAM0

wCurKeys:: db
wNewKeys:: db


SECTION "Utility Functions", ROM0

; Copy bytes from one area to another.
; Invalidates a.
; @param de: Source
; @param hl: Destination
; @param bc: Length
Memcopy::
	ld a, [de]
	ld [hli], a
	inc de
	dec bc
	ld a, b
	or a, c
	jp nz, Memcopy
	ret

; Reads the button inputs.
; Invalidates a and b.
; Updates the variables
;   wCurKeys with the currently pressed keys
;   wNewKeys with the keys that are now pressed that were not pressed before
; Taken from https://gbdev.io/gb-asm-tutorial/part2/input.html
UpdateKeys::
	; Poll half the controller
	ld a, JOYP_GET_BUTTONS
	call .onenibble
	ld b, a ; B7-4 = 1; B3-0 = unpressed buttons

	; Poll the other half
	ld a, JOYP_GET_CTRL_PAD
	call .onenibble
	swap a ; A3-0 = unpressed directions; A7-4 = 1
	xor a, b ; A = pressed buttons + directions
	ld b, a ; B = pressed buttons + directions

	; And release the controller
	ld a, JOYP_GET_NONE
	ldh [rP1], a

	; Combine with previous wCurKeys to make wNewKeys
	ld a, [wCurKeys]
	xor a, b ; A = keys that changed state
	and a, b ; A = keys that changed to pressed
	ld [wNewKeys], a
	ld a, b
	ld [wCurKeys], a
	ret
.onenibble
	ldh [rP1], a ; switch the key matrix
	call .knownret ; burn 10 cycles calling a known ret
	ldh a, [rP1] ; ignore value while waiting for the key matrix to settle
	ldh a, [rP1]
	ldh a, [rP1] ; this read counts
	or a, $F0 ; A7-4 = 1; A3-0 = unpressed keys
.knownret
	ret

; Waits until the next VBlank period.
; Invalidates a.
WaitVBlank::
	ld a, [rLY]  ; Copy the vertical line to a
	cp 144  ; Check if the vertical line is 144
	jp c, WaitVBlank  ; if yes, we can return, otherwise, wait for longer
	ret
