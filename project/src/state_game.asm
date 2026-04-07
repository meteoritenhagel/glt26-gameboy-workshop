INCLUDE "./include/constants.inc"
INCLUDE "./include/hardware.inc"


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

    ; Turn the LCD on
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a
    
GameplayLoop:
    jr GameplayLoop




SECTION "Game Tiles", ROM0
GameTiles:
    INCBIN "./build/game.2bpp"
GameTilesEnd:


SECTION "Game Tilemaps", ROM0
GameTilemap:
    INCBIN "./build/game.tilemap"
GameTilemapEnd: