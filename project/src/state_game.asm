INCLUDE "./include/constants.inc"
INCLUDE "./include/hardware.inc"

DEF START_BEAT_DURATION EQU 20

DEF PLAYER_ARROW_REGION_START EQU $99A2
DEF TILE_WHITE EQU $01
DEF TILE_ARROW EQU $08
DEF TILE_EMPTY_BOX EQU $0E
DEF TILE_FULL_BOX EQU $0D

SECTION "State Game Variables", WRAM0

wBeatDuration:: db  ; Increases by one during each VBlank and resets if it reaches 60

SECTION "State Game Functions", ROM0


; Mutes all sound channels.
; @destroys a c e hl
StopSounds:
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


; Plays a weak beat.
PlayWeakBeat:
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

; Plays a strong beat.
PlayStrongBeat:
    push af
    push bc
    push de
    push hl
    ld hl, music_strongbeat
    call hUGE_init
    pop hl
    pop de
    pop bc
    pop af
    ret


InitStateGame::
    ; Initialize beat duration
    ld a, START_BEAT_DURATION
    ld [wBeatDuration], a

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

    ; Turn the LCD on
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a

    call FadeFromBlack

    ld hl, PLAYER_ARROW_REGION_START  ; set the starting position on the screen

GameplayLoop:
    ; First, execute the metronome.
    ld a, [wBeatDuration]
    ld d, a  ; d is the duration of frames between two pulses
    call PlayMetronome

    ; Second, register the player input
    call PlayerInput
    
.done
    jr .done


; The metronome helps the player find the pulse before
; having to enter the rhythm by themselves later in the
; second phase of each round.
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

; Get the player input, this is the second phase of each round.
; @param d: duration between two pulses in frames (approx. 1/60 sec)
; @param hl: address of the starting position on the screen
; @destroys af bc
PlayerInput:
    ld c, 8  ; fill eight boxes, c is our counter
.loop
    ld a, TILE_ARROW
    ld [hl], a

    call PlayWeakBeat

    ld e, d  ; load the number of frames to wait into e
    call WaitMultipleVBlankPlayerInput

    ld a, TILE_WHITE  ; after waiting, replace the arrow by a white box
    ld [hli], a       ; and go one position to the right

    dec c
    jr nz, .loop
    ret


; Waits a number of VBlank periods (1 VBlank is approx. 16.7 ms)
; and checks for user input. If input was found, the box one row
; below the position hl is pointing to is changed to a full box.
; @param e: Number of VBlank periods to wait
; @destroys a b
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
    jr z, .noInputResume
    call PlayStrongBeat
    ld a, l
    add $20
    ld l, a
    ld a, TILE_FULL_BOX
    ld [hl], a
    ld a, l
    sub $20
    ld l, a
.noInputResume
	dec e
	jr .waitForPlayerInputLoop


SECTION "Game Tiles", ROM0
GameTiles:
    INCBIN "./build/game.2bpp"
GameTilesEnd:

SECTION "Game Tilemaps", ROM0
GameTilemap:
    INCBIN "./build/game.tilemap"
GameTilemapEnd: