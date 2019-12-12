; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass:
;
; Mini dycp code

        MATRIX = $00f0 + 8
        CHARSET = $2800
        WIDTH = 24
        HEIGHT = 4
        SCROLL_SPEED = 1

setup .proc
        ldy #0
        clc
-
        tya
        ldx #0
-
row     sta @wMATRIX,x
        adc #HEIGHT
        inx
        cpx #WIDTH
        bne -
        lda row + 1
        adc #39 ; C = 1
        sta row + 1
        bcc +
        inc row +2
+
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

        ldx #23
-       lda #0
        sta sinus,x
        sta text,x
        lda #3
        sta $d800 + (MATRIX & $03ff),x
        sta $d828 + (MATRIX & $03ff),x
        sta $d850 + (MATRIX & $03ff),x
        sta $d878 + (MATRIX & $03ff),x

        dex
        bpl -
        rts
.pend

        .align 256
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


        .align 256
update  .proc
        ldy #0
        ldx #0
        clc
-
        lda ytable,y
        sta sinus,x
        iny
        cpy #48
        bcc +
        ldy #0
+       inx
        cpx #24
        bne -
;        lda update + 1
;        clc
;        adc #01
;        cmp #48
;        bcc +
;        sbc #48
;+       sta update + 1

        ldy update + 1
        iny
        cpy #48
        bcc +
        ldy #0
+       sty update + 1
        rts
.pend


        .align 256

scroll .proc
        lda #0
        sec
        sbc #SCROLL_SPEED
        and #07
        sta scroll +1
        bcc +
        rts
+
        ; move text
        ldx #0
-       lda text + 1,x
        sta text + 0 ,x
        inx
        cpx #23
        bne -

txtidx  lda scrolltext
        bmi end
        asl
        asl
        asl
        sta text + 23
        inc txtidx + 1
        bne +
        inc txtidx + 2
+
        rts
end
        lda #<scrolltext
        ldx #>scrolltext
        sta txtidx + 1
        stx txtidx + 2
        rts
.pend


sinus = MATRIX - 8 + (40 * 4)   ; $c8 - 8 + $a0 = $160-$177
text = sinus+ 24 ; $178-$18f


;        .align 256
;        .align 256
scrolltext
        .enc "screen"
        .text "hello world focus rules "
        .byte $ff
