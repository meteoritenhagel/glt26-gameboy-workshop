INCLUDE "./include/constants.inc"
INCLUDE "./include/hardware.inc"
INCLUDE "./include/hUGE.inc"


SECTION "VBLANK Interrupt Handler", ROM0[$0040]
	; Whenever the Game Boy enters the VBlank period
	; (given that the VBlank interrupt is enabled!),
	; it executes the instruction at position ROM0[$0040].
	;
	; However, we don't have much space to do here,
	; since the LCD interrupt address is already at $0048,
	; so we only have 8 bytes of instruction to use.
	;
	; Let's do a jump to another place, this takes us
	; 3 bytes, which is okay.
	;
	; Interrupts are disabled whenever an interrupt
	; handler is entered, so don't forget to reti
	; instead of ret!
	jp VBlankHandler


SECTION "Header", ROM0[$100]
	jp EntryPoint
	ds $150 - @, 0 ; Make room for the header


SECTION "Entry", ROM0

EntryPoint:
	; We start the game with the title screen!
	ld a, STATE_TITLE
	ld [wNextState], a

	xor a
	ld [wUpdateSound], a  ; Do not update sound for now, only when a music piece is loaded
	ld [wFrameCounter], a  ; Initialize frame counter

	; Initialize audio
	ld a, AUDENA_ON  ; abbreviation of %10000000
	ld [rAUDENA], a  ; Audio Master Control, also known as NR52
	ld a, $FF
	ld [rAUDTERM], a  ; Sound Panning, aka NR51, all channels both left and right
	ld a, $77
	ld [rAUDVOL], a  ; Audio Master Volume, aka NR50, all channels on full volume

	; Allow for VBlank interrupts
	ld a, IE_VBLANK
	ld [rIE], a  ; enable VBlank
	ei  ; activate interrupts in general

StateChange:  ; change to the requested game state
	; case wNextState
	ld a, [wNextState]
	cp STATE_TITLE
	jr nz, .notTitle
	call InitStateTitle  ; STATE_TITLE
	jr StateChange
.notTitle
	cp STATE_GAME
	jr nz, .notGame
	call InitStateGame  ; STATE_GAME
.notGame
	jr StateChange


; The VBlankHandler 
VBlankHandler:
	; first, save the state of every register
	push af
	push bc
	push de
	push hl

	; Update sound if needed
	ld a, [wUpdateSound]
	cp 0
	call nz, hUGE_dosound

	; now, restore the state of every register
	pop hl
	pop de
	pop bc
	pop af

	; we return from the interrupt handler and enable interrupts again!
	reti

