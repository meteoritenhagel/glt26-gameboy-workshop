INCLUDE "./include/hardware.inc"


SECTION "Utility Functions", ROM0

; Copy bytes from one area to another.
; @param de: Source
; @param hl: Destination
; @param bc: Length
; @destroys a
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
; Updates the variables
;   wCurKeys with the currently pressed keys
;   wNewKeys with the keys that are now pressed that were not pressed before
; Taken from https://gbdev.io/gb-asm-tutorial/part2/input.html
; @destroys a b
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
; @destroys a
WaitVBlank::
	; Wait until it's not VBlank
	ld a, [rLY]
	cp 144
	jp nc, WaitVBlank  ; check if the vertical line >= 144, then we are in VBlank
.loop
	; Wait until VBlank and return
	ld a, [rLY]  ; Copy the vertical line to a
	cp 144       ; Check if the vertical line < 144
	jp c, .loop  ; if no, wait for longer
	ret          ; otherwise, return


; Waits a number of VBlank periods (1 VBlank is approx. 16.7 ms).
; @param a: Number of VBlank periods to wait
; @destroys b
WaitMultipleVBlank::
	and a
.loop
	ret z  ; if a is zero, exit
	ld b, a
	call WaitVBlank
	ld a, b
	dec a
	jr .loop

; Fades from the currently used palette (implicitly assumed to
; be the standard palette) gradually to a black screen.
; @destroys a b
FadeToBlack::	
	ld a, %11111001
	ld [rBGP], a
	ld a, 12
	call WaitMultipleVBlank
	
	ld a, %11111110
	ld [rBGP], a
	ld a, 12
	call WaitMultipleVBlank
	
	ld a, %11111111
	ld [rBGP], a
	ld a, 12
	call WaitMultipleVBlank
	ret

; Fades from the currently used palette (implicitly assumed to
; be all black palette) gradually to the standard palette.
; @destroys a b
FadeFromBlack::	
	ld a, %11111110
	ld [rBGP], a
	ld a, 12
	call WaitMultipleVBlank
	
	ld a, %11111001
	ld [rBGP], a
	ld a, 12
	call WaitMultipleVBlank
	
	ld a, %11100100
	ld [rBGP], a
	ld a, 12
	call WaitMultipleVBlank
	ret