INCLUDE "./include/charmap.inc"  ; specify the encoding that is used for the font characters
INCLUDE "./include/constants.inc"
INCLUDE "./include/hardware.inc"

DEF TOP_TEXT_REGION_START EQU $9862
DEF BOTTOM_TEXT_REGION_START EQU $9962
DEF GIVEN_BEAT_REGION_START EQU $98CA
DEF METRONOME_ARROW_REGION_START EQU $99A2
DEF PLAYER_BEAT_REGION_START EQU $99CA

DEF TILE_WHITE EQU $01
DEF TILE_ARROW EQU $08
DEF TILE_EMPTY_BOX EQU $0E
DEF TILE_FULL_BOX EQU $0D


SECTION "State Game Variables", WRAM0

wCurrentGivenBeat: db    ; The byte storing the beat pattern the player should repeat
wCurrentPlayerBeat: db   ; The player input beat


SECTION "State Game Functions", ROM0

; InitStateTitle starts the game state
InitStateGame::
    ; Stop all sounds/music
    call StopSounds

    call WaitVBlank

    ; Turn the LCD off
    xor a
    ld [rLCDC], a

	; Copy Title Tiles
	ld de, GameTiles
    ld hl, $9000
    ld bc, GameTilesEnd - GameTiles
	call Memcopy

	; Copy Title Tilemap
	ld de, GameTilemap
    ld hl, $9800
    ld bc, GameTilemapEnd - GameTilemap
	call Memcopy

    ; Copy Font Tiles into tile memory $8800
	ld de, FontTiles
    ld hl, $8800
    ld bc, FontTilesEnd - FontTiles
	call Memcopy

    ; Draw the text
    ld de, TOP_TEXT_REGION_START
    ld hl, TopText
    call DrawText
    ld de, BOTTOM_TEXT_REGION_START
    ld hl, BottomText
    call DrawText

    ; Turn the LCD on
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a
    
    call InitGivenBeat
GameplayLoop:
    call ClearPlayerInput  ; clear player input each round

    ld hl, METRONOME_ARROW_REGION_START  ; set the starting position on the screen
    
    ; First, execute the metronome.
    ld d, 20  ; d is the duration of frames between two pulses
    call PlayMetronome
    
    ; note that hl was incremented during PlayMetronome,
    ; so we're at the correct position already!
    call PlayerInput

    jr GameplayLoop


; Initializes the given beat state of the current round, i.e.,
; the beat that should be repeated by the player later.
; @destroys a b hl
InitGivenBeat:
    ; determine the random beat pattern of the current round
    call GetRandomByte
    ld [wCurrentGivenBeat], a

    ld hl, GIVEN_BEAT_REGION_START

    ld b, %00000001  ; our bitmask to test the value of each beat bit
.loop
    ld a, [wCurrentGivenBeat]
    and a, b
    jr z, .beatIsZero
    ; current bit is one
    ld a, TILE_FULL_BOX
    jr .continue
.beatIsZero  ; current bit is zero
    ld a, TILE_EMPTY_BOX
.continue
    ld [hli], a

    rlc b  ; test next bit
    jp nc, .loop
    ret  ; return if carry flag is set, i.e., all bits were tested


; The metronome helps the player find the pulse before
; having to enter the rhythm by themselves later in the
; second phase of each round. It is an arrow that moves
; one box per pulse to the right.
; @param d: duration between two pulses in frames (approx. 1/60 sec)
; @param hl: address of the starting position on the screen
; @destroys af bc
PlayMetronome:
    ld c, 8  ; fill eight boxes, c is our counter
.loop
    ld a, TILE_ARROW
    ld [hl], a

    call PlayWeakBeat

    ld a, d  ; wait a bit
    call WaitMultipleVBlank

    ; move arrow one to the right
    ld a, TILE_WHITE
    ld [hli], a

    dec c
    jr nz, .loop
    ret


; Clears the player input from the previous round, i.e., resets
; all player beat boxes to empty boxes.
; @destroys a b hl
ClearPlayerInput:
    ; player beat should start empty
    xor a
    ld [wCurrentPlayerBeat], a

    ; set start position on screen
    ld hl, PLAYER_BEAT_REGION_START

    ld b, 8  ; our counter for traversing all eight boxes
.loop
    ld a, TILE_EMPTY_BOX
    ld [hli], a
    dec b
    jp nz, .loop
    ret  ; return if zero, i.e., all eight boxes were filled


; Get the player input, this is the second phase of each round.
; @param d: duration between two pulses in frames (approx. 1/60 sec)
; @param hl: address of the starting position on the screen
; @destroys af bc e
PlayerInput:
    ld c, %00000001  ; our bitmask for setting the correct bit on the player input
.loop
    ld a, TILE_ARROW
    ld [hl], a

    call PlayWeakBeat

    ld e, d  ; load the number of frames to wait into e
    call WaitMultipleVBlankPlayerInput

    ld a, TILE_WHITE  ; after waiting, replace the arrow by a white box
    ld [hli], a       ; and go one position to the right

    rlc c  ; test next bit
    jp nc, .loop
    ret  ; return if carry flag is set, i.e., all bits were tested


; Waits a number of VBlank periods (1 VBlank is approx. 16.7 ms)
; and checks for user input. If input was found, the box one row
; below the position hl is pointing to is changed to a full box.
; @param c: Bit mask of bit to set in [wCurrentPlayerBeat] if a
;           beat was registered.
; @param e: Number of VBlank periods to wait
; @destroys a b e
WaitMultipleVBlankPlayerInput:
    ld a, e
    and e
.waitForPlayerInputLoop
	ret z  ; if we have waited enough, return
	call WaitVBlank
    ; our custom callback
    call UpdateKeys
    ld a, [wNewKeys]
    and a
    jr z, .noInputResume  ; if no input was found, go on
    call PlayStrongBeat  ; if input was found, play the strong beat
    ; then, go to the box one column below and change it from empty to full
    ld a, l
    add $20  ; to go one column down, add $20
    ld l, a
    ld a, TILE_FULL_BOX
    ld [hl], a
    ld a, l
    sub $20
    ld l, a
    ; Finally, set the bit according to the bitmask if a player input
    ; was registered
    ld a, [wCurrentPlayerBeat]
    or a, c
    ld [wCurrentPlayerBeat], a
.noInputResume
	dec e
	jr .waitForPlayerInputLoop


SECTION "Game Text", ROM0
TopText: db "COPY THE RHYTHM!", 255  ; 255 signifies end of line
BottomText: db "YOU", 255


SECTION "Game Tiles", ROM0
GameTiles:
    INCBIN "./build/game.2bpp"
GameTilesEnd:

FontTiles:
    INCBIN "./build/font.2bpp"
FontTilesEnd:


SECTION "Game Tilemaps", ROM0
GameTilemap:
    INCBIN "./build/game.tilemap"
GameTilemapEnd: