; General constants
DEF STATE_TITLE EQU 0  ; for title state
DEF STATE_GAME  EQU 1  ; for gameplay state

; Gameplay constants
DEF START_BEAT_DURATION EQU 35  ; the initial duration between pulses in the game measured in frames
DEF DECREASE_DURATION EQU 7     ; the amount by which the duration between pulses is decreased after each successful round
DEF MINIMUM_DURATION EQU 40      ; The minimal duration between pulses in frames. If the round's duration is below, the game is finished