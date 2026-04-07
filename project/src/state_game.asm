INCLUDE "./include/charmap.inc"  ; specify the encoding that is used for the font characters
INCLUDE "./include/constants.inc"
INCLUDE "./include/hardware.inc"

DEF TOP_TEXT_REGION_START EQU $9862
DEF BOTTOM_TEXT_REGION_START EQU $9962
DEF METRONOME_ARROW_REGION_START EQU $99A2

DEF TILE_WHITE EQU $01
DEF TILE_ARROW EQU $08


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
    
GameplayLoop:
    ld hl, METRONOME_ARROW_REGION_START  ; set the starting position on the screen
    
    ; First, execute the metronome.
    ld d, 20  ; d is the duration of frames between two pulses
    call PlayMetronome

    jr GameplayLoop


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