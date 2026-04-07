INCLUDE "./include/charmap.inc"  ; specify the encoding that is used for the font characters
INCLUDE "./include/constants.inc"
INCLUDE "./include/hardware.inc"

DEF TOP_TEXT_REGION_START EQU $9862
DEF BOTTOM_TEXT_REGION_START EQU $9962


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
    jr GameplayLoop


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