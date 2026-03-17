INCLUDE "./include/hardware.inc"


SECTION "Header", ROM0[$100]
	jp EntryPoint
	ds $150 - @, 0 ; Make room for the header

EntryPoint:
	; wait until VBlank to turn the LCD off, otherwise, the display
	; might take damages
	call WaitVBlank

	; Turn the LCD off
    xor a
    ld [rLCDC], a

	; Copy Tiles
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
	ld a, %11100100  ; default palette white:light:dark:black
	ld [rBGP], a

.loop
	jp .loop


SECTION "Tiles", ROM0
TitleTiles::
INCBIN "./build/title.2bpp"
TitleTilesEnd::

SECTION "Tilemaps", rom0
TitleTilemap::
INCBIN "./build/title.tilemap"
TitleTilemapEnd::