; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass:
;
;
;
        ZP = $10

        RASTER = $30 + 5 * 8

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
        sei
        ldx #$ff
        txs
        cld
        bit $dc0d
        bit $dd0d
        lda #$06
        sta $d020
        sta $d021
        lda #$7f
        sta $dc0d
        sta $dd0d

        lda #<irq1
        ldx #>irq1
        ldy #RASTER
        sta $0314
        stx $0315
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
;        jsr player.init
        cli
        jmp *

irq1
        inc $d020
        ldx #13
-       dex
        bpl -
        lda #$08
        ldx dycp.scroll + 1
        sta $d018
        stx $d016
        dec $d020

#trigger_irq irq2, RASTER + ((4 * 8) + 1)

irq2
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
        inc $d020
        inc $d020
        inc $d020
        inc $d020

        lda #<irq1
        ldx #>irq1
        ldy #RASTER

do_irq
        sta $0314
        stx $0315
        sty $d012
        inc $d019
        jmp $ea81



       ;* = $1000

dycp    .binclude "dycp.s"


        .align 256
        FONT = *
.binary "font000.prg", 2
