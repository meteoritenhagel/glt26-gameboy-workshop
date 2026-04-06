INCLUDE "./include/constants.inc"
INCLUDE "./include/hardware.inc"


SECTION "State Title Functions", ROM0


; InitStateTitle displays the title screen
InitStateTitle::
    ; wait until VBlank to turn the LCD off, otherwise, the display
	; might take damages
	call WaitVBlank

	; Turn the LCD off
    xor a
    ld [rLCDC], a

	; Copy Title Tiles
	ld de, TitleTiles
    ld hl, $9000
    ld bc, TitleTilesEnd - TitleTiles
	call Memcopy

	; Copy Title Tilemap
	ld de, TitleTilemap
    ld hl, $9800
    ld bc, TitleTilemapEnd - TitleTilemap
	call Memcopy

    ; Turn the LCD on
    ld a, LCDC_ON | LCDC_BG_ON
    ld [rLCDC], a

	; During the first (blank) frame, initialize display registers
	ld a, %11100100  ; default palette black:dark:light:white
	ld [rBGP], a

    ret


SECTION "Title Tiles", ROM0
TitleTiles:
    INCBIN "./build/title.2bpp"
TitleTilesEnd:


SECTION "Title Tilemaps", ROM0
TitleTilemap:
    INCBIN "./build/title.tilemap"
TitleTilemapEnd: