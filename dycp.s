; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass:
;
; Mini dycp code

scrolltext
        .enc "screen"
        .text "hello world   focus rules   "
        .byte $1b, $1c, $1d, $1e, $1f
        .byte $ff
