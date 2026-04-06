INCLUDE "./include/constants.inc"
INCLUDE "./include/hardware.inc"


SECTION "State Game Functions", ROM0

; InitStateTitle starts the game state
InitStateGame::
    
GameplayLoop:
    jr GameplayLoop