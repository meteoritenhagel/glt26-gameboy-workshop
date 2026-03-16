SECTION "Game Variables", WRAM0
wGameState:: db ; for the game states, refer to constanst GAME_STATE_* in constants.inc
SECTION "Counter", WRAM0
wTimerCounter:: db ; since "PRESS START" is supposed to blink each second, we must count the timer events
wVBlankCount:: db ; VBlank counter

SECTION "Input Variables", WRAM0
wCurKeys:: db ; currently pressed keys
wNewKeys:: db ; newly pressed keys