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
; This function is important, since only
; in the VBlank period we are allowed to
; switch off the LCD screen (needed for
; accessing VRAM). Otherwise, hardware
; damage may occur!
; @destroys a
WaitVBlank::
	; Wait until it's not VBlank,
	; i.e., vertical line [rLY] >= 144
	ld a, [rLY]
	cp 144
	; check if the vertical line < 144,
	; i.e., we are in VBlank. If so, jump
	; to the start and wait a little longer.
	jp nc, WaitVBlank
.loop
	; Wait until next VBlank and return
	ld a, [rLY]  ; Copy the vertical line to a
	cp 144       ; Check if the vertical line < 144
	jp c, .loop  ; if no, wait for longer
	ret          ; otherwise, we are in VBlank and return


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


; Mutes all sound channels.
; @destroys a c e hl
StopSounds::
    ; Stop any sounds
    ld c, 1  ; c = 1 means mute
    ld b, 0  ; channel 1
    call hUGE_mute_channel
    ld c, 1 
    ld b, 1  ; channel 2
    call hUGE_mute_channel
    ld c, 1 
    ld b, 2  ; channel 3
    call hUGE_mute_channel
    ld c, 1 
    ld b, 3  ; channel 4
    call hUGE_mute_channel
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


; Plays a weak beat.
PlayWeakBeat::
    push af
    push bc
    push de
    push hl
    ld hl, music_weakbeat
    call hUGE_init
    pop hl
    pop de
    pop bc
    pop af
    ret
