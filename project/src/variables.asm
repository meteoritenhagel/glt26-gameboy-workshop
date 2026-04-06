INCLUDE "./include/hardware.inc"

SECTION "Variables", WRAM0

wUpdateSound:: db   ; If nonzero, update the sound during the VBlank interrupt.
wNextState:: db     ; game state that should be toggled next 

wCurKeys:: db       ; currently pressed keys
wNewKeys:: db       ; newly pressed keys
