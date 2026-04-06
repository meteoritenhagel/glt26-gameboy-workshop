INCLUDE "./include/hardware.inc"

SECTION "Utility Functions Variables", WRAM0

wRandState:: ds 4   ; random state


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


; Draws text on a position on screen.
; @param de: Pointer to the position on the screen.
; @param hl: Pointer to text that is to be drawn.
; @destroys a 
DrawText::	
	; Check for the end of string character 255
	ld a, [hl]
	cp 255
	ret z  ; if end of string was found, return

	; Write the current character (in hl) to the address
	; on the tilemap (in de)
	ld a, [hl]
	; note that our text is loaded into the tiles at $8800,
	; and these tiles start being indexed at $80, so we have
	; to add this value
	add $80
	ld [de], a

	; move to the next character and next background tile
	inc hl
	inc de

	jp DrawText

;; Adapted from: https://github.com/pinobatch/libbet/blob/master/src/rand.z80#L34-L54
; Generates a pseudorandom 16-bit integer in BC
; using the LCG formula from cc65 rand():
; x[i + 1] = x[i] * 0x01010101 + 0xB3B3B3B3
; @return a: state bits 31-24 (which have the best entropy)
; @destroys hl
GetRandomByte::
  ; Add 0xB3 then multiply by 0x01010101
  ld hl, wRandState+0
  ld a, [hl]
  add a, $B3
  ld [hl+], a
  adc a, [hl]
  ld [hl+], a
  adc a, [hl]
  ld [hl+], a
  adc a, [hl]
  ld [hl], a
  ret
