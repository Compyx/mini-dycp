; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass:
;
;
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
        sta $d021
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

        ldx #$00
        stx $dc0e
        stx $dd0e
        inx
        stx $d01a

        inc $d019

        jsr dycp.setup
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
        .fill 11, $ea
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
        lda #$15
        sta $d018
logo_d016
        lda #$08
        sta $d016
        inc $d020

delay   ldx #$11
-       dex
        bne -

        lda #0
delay2
        beq +
+
        cpx #$e0
        cpx #$e0
        bit $ea

        lda #$39
        ldx #$3b
        sta $d011
        stx $d011
;        jsr vsp_start




        ldy #$32 + 6* 8 -1
        lda #<irq1
        ldx #>irq1
        jmp do_irq

irq1
        pha
        txa
        pha
        tay
        pha
        ldx #7
-       dex
        bpl -
        lda #$1b
        sta $d011
        lda #$08
        ldx dycp.scroll + 1
        sta $d018
        stx $d016
        lda #4
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


        lda #$32+ (6+4) *8 - 2
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
        dec $d020
        ldx #13
-       dex
        bpl -
        lda #$15
        sta $d018
        lda #$08
        sta $d016
        jsr dycp.clear
        dec $d020
        jsr dycp.update
        dec $d020
        jsr dycp.scroll
        dec $d020
        jsr dycp.render
        dec $d020
        jsr handle_delay
        jsr vsp_update
        jsr show_delay
        inc $d020
        inc $d020
        inc $d020
        inc $d020
        inc $d020

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

vsp_start
logo_xpos
        lda #$03
        sta _offset +1
        sta $d020
        lda #$39
        ldx #$3b
        sta $d011
_offset bne +
+
        .fill 40, $e0
        bit $ea
        nop
        nop
        bit $ea
        stx $d011
        rts


vsp_update
        ldx #0
        lda dycp.ytable,x
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
        sta logo_xpos + 1

        lda vsp_update + 1
        clc
        adc #1
        tax
        cpx #48
        bcc +
        ldx #0
+
        stx vsp_update + 1
        rts

handle_delay
        ldx #$1b
        beq ++
        dex
        bpl +
        ldx #$1b
+       stx handle_delay+1
        rts
+
        lda $dc01
        and #$02

        beq +
        rts
+
        ldx #$1b
        stx handle_delay + 1
        and #$08
        beq +
        rts
+
        lda delay2 + 1
        sec
        sbc #1
        bcc +
        sta delay2 + 1
        rts
+
        lda #4
        sta delay2 + 1

        ldx delay + 1
        inx
        cpx #40
        bcc +
        ldx #0
+
        stx delay + 1
        rts

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


dycp    .binclude "dycp.s"

        .align 256
        FONT = *
.binary "font000.prg", 2


        * = SID_LOAD
.binary format("%s", SID_PATH), $7e
