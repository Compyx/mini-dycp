; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass:
;
; Mini dycp code

        MATRIX = $00f0 + 8
        CHARSET = $2800
        WIDTH = 24
        HEIGHT = 4
        SCROLL_SPEED = 1


sinus = MATRIX - 8 + (40 * 4)   ; $c8 - 8 + $a0 = $160-$177
text = sinus+ 24 ; $178-$18f


scrolltext
        .enc "screen"
        .text "hello world   focus rules   "
        .byte $1b, $1c, $1d, $1e, $1f
        .byte $ff
