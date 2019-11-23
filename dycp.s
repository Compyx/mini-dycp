; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass:
;
; Mini dycp code

        MATRIX = $0400
        FONT = $1f00
        CHARSET = $2000
        WIDTH = 24
        HEIGHT = 4

sinus   .byte range(24)
text    .byte range($08, $f8, $08)


setup .proc
        ldy #0
        clc
-
        tya
        ldx #0
-
row     sta MATRIX,x
        adc #HEIGHT
        inx
        cpx #WIDTH
        bne -
        lda row + 1
        adc #39 ; C = 1
        sta row + 1
        iny
        cpy #HEIGHT
        bne --  ; C = 0

        ldx #0
        txa
-       sta CHARSET,x
        sta CHARSET + 256,x
        sta CHARSET + 512,x
        inx
        bne -
        rts
.pend


render .proc
        ldx #0
        stx ZP + 2
        lda #<CHARSET
        sta ZP
        lda #>CHARSET
        sta ZP + 1
-
        ldy sinus,x
        lda text,x
        tax
        lda FONT,x
        sta (ZP),y
        iny
        lda FONT+1,x
        sta (ZP),y
        iny
        lda FONT+2,x
        sta (ZP),y
        iny
        lda FONT+3,x
        sta (ZP),y
        iny
        lda FONT+4,x
        sta (ZP),y

        lda ZP
        clc
        adc #4*8
        sta ZP
        bcc +
        inc ZP +1
+
        inc ZP + 2
        ldx ZP + 2
        cpx  #24
        bne -

        rts
.pend

clear .proc
        ldx #0
        stx ZP + 2

        lda #<CHARSET
        sta ZP + 0
        lda #>CHARSET
        sta ZP + 1
-
        ldy sinus,x
        lda #0
        ldx #4
-       sta (ZP),y
        iny
        dex
        bpl -

;        sta (ZP),y
;        iny
;        sta (ZP),y
;        iny
;        sta (ZP),y
;        iny
;        sta (ZP),y
;        iny
;        sta (ZP),y

        lda ZP
        clc
        adc #4*8
        sta ZP
        bcc +
        inc ZP +1
+
        inc ZP + 2
        ldx ZP + 2
        cpx #24
        bne --
        rts
.pend


update  .proc
        ldy #0
        ldx #0
-
        lda ytable,y
        sta sinus,x
        inx
        iny
        cpx #24
        bne -
        lda update + 1
        clc
        adc #01
        cmp #48
        bcc +
        sbc #48
+       sta update + 1
        rts
.pend

        .align 256
ytable  .byte 12 + 11.5 * sin(range(96) * rad(360.0/48.0))

        .align 256



