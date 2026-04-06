INCLUDE "./include/constants.inc"
INCLUDE "./include/hardware.inc"


SECTION "State Title Functions", ROM0


; InitStateTitle displays the title screen
InitStateTitle::
    ; Initialize music playback
    xor a
	ld [wUpdateSound], a  ; disable sound updates on VBlank
    ld hl, music_title  ; the label is visible in music_title.asm
    call hUGE_init  ; load title song into hUGE
    ld a, 1
    ld [wUpdateSound], a  ; enable sound updates on VBlank

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

ChangePaletteLoop:
    ld e, 30  ; wait for approx. half a second
    call WaitMultipleVBlankPressStart
    jr nz, .exitState
    ld a, %11010100  ; new palette black:light:light:white, what has been dark now is light, too
	ld [rBGP], a

    ld e, 30  ; wait for approx. half a second
    call WaitMultipleVBlankPressStart
    jr nz, .exitState
    ld a, %11100100  ; revert back to default palette black:dark:light:white
	ld [rBGP], a

    jr ChangePaletteLoop

.exitState
    ld a, STATE_GAME
    ld [wNextState], a  ; Set the next game state to GAME
    ret


; Waits a number of VBlank periods (1 VBlank is approx. 16.7 ms)
; and checks for start button press. If start was pressed, the loop is
; exited with zero flag ZF = 1.
; @param e: Number of VBlank periods to wait
; @returns f ZF = 1 if start was pressed
; @destroys a b
WaitMultipleVBlankPressStart:
    ld a, e
    and e
.waitForPlayerInputLoop
	ret z  ; if we have waited enough, return
	call WaitVBlank
    ; our custom callback
    call UpdateKeys
    ld a, [wCurKeys]  ; get the currently pressed keys
    and a, PAD_START
    ret nz  ; if start is pressed, immediately exit
	dec e
	jr .waitForPlayerInputLoop


SECTION "Title Tiles", ROM0
TitleTiles:
    INCBIN "./build/title.2bpp"
TitleTilesEnd:


SECTION "Title Tilemaps", ROM0
TitleTilemap:
    INCBIN "./build/title.tilemap"
TitleTilemapEnd: