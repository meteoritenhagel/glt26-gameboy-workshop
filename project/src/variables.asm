INCLUDE "./include/hardware.inc"

SECTION "Variables", WRAM0

; Enter your global variables here,
; e.g. wUpdateSound:: db
; declares the variable wUpdateSound
; (which is a 16-bit pointer to an
; 8-bit value in memory)

; General variables
wUpdateSound:: db   ; If nonzero, update the sound during the VBlank interrupt.
wNextState:: db     ; game state that should be toggled next 

; Keyboard input variables (used by UpdateKeys in utils.asm)
wCurKeys:: db       ; currently pressed keys
wNewKeys:: db       ; newly pressed keys
