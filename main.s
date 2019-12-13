; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass:
;
; $2800-$2aff = dycp
;
        SID_ENABLE= 1
        SID_LOAD = $1000
        SID_PATH = "Plaster.sid"
        SID_INIT = SID_LOAD + 0
        SID_PLAY = SID_LOAD + 3

        ZP_TMP = $10
        ZP = $20

        RASTER = $2d

; BASIC SYS line
        * = $0801
        .word (+), 2019
        .null $9e, format("%d", start)
+       .word 0


trigger_irq .macro
        lda #<(\1)
        ldx #>(\1)
        ldy #\2
        jmp do_irq
.endm

        * = $2000
start
        lda #$00
        sta $0286
        jsr $e536
        sei
        ldx #$ff
        txs
        cld
        lda #$35
        sta $01
        bit $dc0d
        bit $dd0d
        lda #$06
        sta $d020
        lda #$7f
        sta $dc0d
        sta $dd0d

        lda #<irq0
        ldx #>irq0
        ldy #RASTER
        sta $fffe
        stx $ffff
        sty $d012
        lda #$1b
        sta $d011
        lda #$08
        sta $d018

        ldx #$00
        stx $d021
        stx $dc0e
        stx $dd0e
        inx
        stx $d01a

        inc $d019

        lda #$aa
        sta $3fff

        jsr logo_setup
        jsr dycp_setup
.if SID_ENABLE
        ldx #$0f
-       lda $f0,x
        sta ZP_TMP,x
        dex
        bpl -
        jsr SID_INIT
.fi
        cli

        jmp *
irq0
        pha
        txa
        pha
        tya
        pha

        lda #<irq0a
        ldx #>irq0a
        ldy #RASTER + 1
        sty $d012
        sta $fffe
        stx $ffff
        nop
        inc $d019
        tsx
        cli
        .fill 11, $ea   ; reduce?
irq0a
        txs
        ldx #8
-       dex
        bne -
        bit $ea
        lda $d012
        cmp $d012
        beq +
+
        dec $d020

        jmp deicide

        * = $2168
deicide
        lda #$b8
        sta $d018
logo_d016
        lda #$18
        sta $d016
        inc $d020

delay   ldx #$15
-       dex
        bne -
        nop
        nop
        lda #0
vsp_idx
        beq +
+
        .fill 40, $e0
        bit $ea

        lda #$39
        ldx #$3b
        sta $d011
        stx $d011

        lda #5
        sta $d020
.if SID_ENABLE
        ldx #$0f
-       lda ZP_TMP,x
        sta $f0,x
        dex
        bpl -

        jsr SID_PLAY

        ldx #$0f
-       lda $f0,x
        sta ZP_TMP,x
        dex
        bpl -
.fi

        lda #0
        sta $d020

        ldy #$32 + 5* 8  - 2
        lda #<irq1
        ldx #>irq1
        jmp do_irq

        * = $23e8
dycp_render .proc
        ldx #0
        stx ZP + 2
        lda #<dycp.CHARSET
        sta ZP
        lda #>dycp.CHARSET
        sta ZP + 1
-
        ldy dycp.sinus,x
        lda dycp.text,x
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



        *= $2b00
        ; *= $4000
irq1
        pha
        txa
        pha
        tya
        pha

        lda #<irq1a
        ldx #>irq1a
        ldy #$32 + 5 * 8 - 1
        sty $d012
        sta $fffe
        stx $ffff
        inc $d019
        tsx
        cli
        .fill 10, $ea
irq1a
        txs
        ldx #8
-       dex
        bne -
        bit $ea
        lda $d012
        cmp $d012
        beq +
+
delay3_major
        ldx #3
-       dex
        bne -
delay3_minor
;        beq *+2         ; 3
;        cpx #$e0        ; 2
;        cpx #$e0        ; 2
;        bit $ea         ; 3

        dec $d020
        jsr fcps2
;        .fill 12, $ea
        inc $d020
        lda #$1b
        sta $d011
        lda #$0a
        ldx dycp_scroll + 1
        stx $d016
        sta $d018



        ;ldx #$08
        ;stx $d016
        ;lda #$08
        ;sta $d018
        sta $d020
        lda #4
        sta $d020



        ;lda #$1b
        ;sta $d011
        lda #$32+ (6+4) * 8 -3
        tay
        lda #<irq2
        ldx #>irq2
        jmp do_irq

irq2
        pha
        tax
        pha
        tya
        pha
        lda #6
        sta $d020
        ldx #20
-       dex
        bpl -
        lda #$15
        sta $d018
        lda #$08
        sta $d016



        jsr dycp_clear
        dec $d020
        jsr dycp_update
        dec $d020
        jsr dycp_scroll
        dec $d020
        jsr dycp_render
        dec $d020
        ;jsr handle_delay
        jsr vsp_update
        ;jsr show_delay
        lda #0
        sta $d020

        lda #<irq0
        ldx #>irq0
        ldy #RASTER
do_irq
        sta $fffe
        stx $ffff
        sty $d012
        inc $d019
        pla
        tay
        pla
        tax
        pla
        rti

dycp_scroll .proc
        lda #0
        sec
        sbc #dycp.SCROLL_SPEED
        and #07
        sta dycp_scroll +1
        bcc +
        rts
+
        ; move text
        ldx #0
-       lda dycp.text + 1,x
        sta dycp.text + 0 ,x
        inx
        cpx #23
        bne -

txtidx  lda dycp.scrolltext
        bmi end
        asl
        asl
        asl
        sta dycp.text + 23
        inc txtidx + 1
        bne +
        inc txtidx + 2
+
        rts
end
        lda #<dycp.scrolltext
        ldx #>dycp.scrolltext
        sta txtidx + 1
        stx txtidx + 2
        rts
.pend
        * = $2528

.if 0
vsp_start
logo_xpos
        lda #$03
        sta _offset +1
        sta $d020
        lda #$39
        ldx #$3b
_offset bne +
+
        .fill 32, $e0
        bit $ea
        nop
        nop
        bit $ea
        sta $d011
        stx $d011
        rts
.endif

vsp_update
        ldx #0
        lda vsp_table,x
        pha
        and #7
        ora #$10
        sta logo_d016 + 1
        pla
        lsr
        lsr
        lsr
        sta _tmp + 1
        lda #40
        sec
_tmp    sbc #0
        sta vsp_idx + 1

        lda vsp_update + 1
        clc
        adc #1
        tax
+
        txa
        and #$3f
        sta vsp_update + 1
        rts

dycp_setup .proc
        ldy #0
        clc
-
        tya
        ldx #0
-
row     sta @wdycp.MATRIX,x
        adc #dycp.HEIGHT
        inx
        cpx #dycp.WIDTH
        bne -
        lda row + 1
        adc #39 ; C = 1
        sta row + 1
        bcc +
        inc row +2
+
        iny
        cpy #dycp.HEIGHT
        bne --  ; C = 0


        ldx #0
        txa
-       sta dycp.CHARSET,x
        sta dycp.CHARSET + 256,x
        sta dycp.CHARSET + 512,x
        inx
        bne -

        ldx #23
-       lda #0
        sta dycp.sinus,x
        sta dycp.text,x
        lda #3
        sta $d800 + (dycp.MATRIX & $03ff),x
        sta $d828 + (dycp.MATRIX & $03ff),x
        sta $d850 + (dycp.MATRIX & $03ff),x
        sta $d878 + (dycp.MATRIX & $03ff),x

        dex
        bpl -
        rts
.pend
dycp_update  .proc
        ldy #0
        ldx #0
        clc
-
        lda ytable,y
        sta dycp.sinus,x
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

        ldy dycp_update + 1
        iny
        cpy #48
        bcc +
        ldy #0
+       sty dycp_update + 1
        rts
.pend


.if 0
handle_delay .proc
        ldx #$08
        beq ++
        dex
        bpl +
        ldx #$08
+       stx handle_delay+1
        rts
+
        lda $dc01
        and #$10

        beq +
        rts
+
        ldx #$08
        stx handle_delay + 1
        and #$08
        beq +
        rts
+
        lda delay3_minor + 1
        sec
        sbc #1
        bcc +
        sta delay3_minor + 1
        rts
+
        lda #4
        sta delay3_minor + 1

        ldx delay3_major + 1
        inx
+
        stx delay3_major + 1
        rts
.pend
.endif

.if 0
show_delay .proc
        lda delay + 1
        jsr hexdigits
        sta $0600
        stx $0601
        lda delay2 + 1
        jsr hexdigits
        sta $0603
        stx $0604


        lda logo_xpos + 1
        jsr hexdigits
        sta $0606
        sty $0607

        rts
        .pend
.fi

hexdigits .proc
        pha
        and #$0f
        cmp #$0a
        bcc +
        sbc #$39
+       adc #$30
        tax
        pla
        lsr
        lsr
        lsr
        lsr
        cmp #$0a
        bcc +
        sbc #$39
+       adc #$30
        rts
.pend

        * = $22a8
fcps2 .proc
        lda #42
        sec
        sbc vsp_idx +1
        sta offset + 1
        lda #$19
        ldx #$1b
        sta $d011
offset  bne +
+      .fill 40, $e0
        bit $ea
        stx $d011
        rts
.pend


logo_setup .proc
        ldx #LOGO_WIDTH - 1
-       lda logo_colram,x
        sta $d800 +  LOGO_OFFSET + (LOGO_ROW * 40) + 0,x
        lda logo_colram + 20,x
        sta $d800 +  LOGO_OFFSET + (LOGO_ROW * 40) + 40,x
        lda logo_colram + 40,x
        sta $d800 +  LOGO_OFFSET + (LOGO_ROW * 40) + 80,x
        lda logo_colram + 60,x
        sta $d800 +  LOGO_OFFSET + (LOGO_ROW * 40) + 120,x
        dex
        bpl -
        rts
.pend


dycp_clear .proc
        ldx #0
        stx ZP + 2

        lda #<dycp.CHARSET
        sta ZP + 0
        lda #>dycp.CHARSET
        sta ZP + 1
-
        ldy dycp.sinus,x
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


        * = $2f00
        FONT = *
.binary "font000.prg", 2


        * = SID_LOAD
.binary format("%s", SID_PATH), $7e


LOGO_OFFSET = 25
LOGO_WIDTH = 20
LOGO_ROW = 0

; $20c8-$21
; bitmap (interleave with code or data here)
        * = $2000 + LOGO_OFFSET * 8 + (LOGO_ROW * 320)
.for bmp_row = 0, bmp_row < 4, bmp_row += 1
  .binary "focus.kla", 2 + (bmp_row * 320), LOGO_WIDTH * 8
  * += $140 - (LOGO_WIDTH * 8)
.next
;.binary "focus.kla", 2, 5 * 320

; vidram (interleave with code or data here)
        * = $2c00 + LOGO_OFFSET + (LOGO_ROW * 40)
.binary "focus.kla", 2 + 8000, 5 * 40

; colram
        * = $2e00
logo_colram
.for cram_row = 0, cram_row < 4, cram_row += 1
  .binary "focus.kla", 2 + 9000 + (cram_row) * 40 + 0, LOGO_WIDTH
.next

vsp_table
        .byte 64 + 63.5 * sin(range(64) * rad(360.0/64.0))


ytable  .byte 12 + 11.5 * sin(range(48) * rad(360.0/48.0))


        * = $4000



        .align 256

dycp    .binclude "dycp.s"

