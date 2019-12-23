; vim: set et ts=8 sw=8 sts=8 fdm=marker syntax=64tass:
;
; $2000-$25ff = bitmap logo, starts at $20c8 with 20 chars each row, so there's
;               some free space for code/data (pretty much filled at the moment)
; $2800-$2aff = dycp (filled)
; $2c00-$2c9f = bitmap logo vidram (cannot add code there)
;
        SID_ENABLE= 1
        SID_LOAD = $1000
        SID_PATH = "Plaster.sid"
        SID_INIT = SID_LOAD + 0
        SID_PLAY = SID_LOAD + 3

        ZP_TMP = $10
        ZP = $20

        FILL_SPRITE = $40

        RASTER = $2d

        DYCP_MATRIX = $00f0 + 8 + 40    ; $0120-$01bf
        DYCP_CHARSET = $2800
        DYCP_WIDTH = 24
        DYCP_HEIGHT = 4
        DYCP_SCROLL_SPEED = 1

        ; $120 - 8 + (4*40) = $1b8
        dycp_sinus = DYCP_MATRIX - 8 + (40 * 4)
        ; $1b8 + 24 = $1d0
        ; text is 24 bytes: $
        dycp_text = dycp_sinus+ 24 ; $01d0-$01f7


        LOGO_OFFSET = 25
        LOGO_WIDTH = 20
        LOGO_ROW = 0



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
        lda #0
        sta $0286
        jsr $e536
        sei
        ldx #$ff
        txs
        cld
        lda #$35
        sta $01
        lda #$06
        sta $d020
        lda #$7f
        sta $dc0d
        sta $dd0d
        bit $dc0d
        bit $dd0d
        ldx #$01
        stx $d019

        lda #<irq0
        sta $fffe
        lda #>irq0
        sta $ffff
        ldy #RASTER
        sty $d012
        lda #$1b
        sta $d011
        lda #$08
        sta $d018

        stx $d01a

        jsr logo_setup
        jsr dycp_setup
        jsr sprites_setup
.if SID_ENABLE
 ;       ldx #$0f
-;       lda $f0,x
 ;       sta ZP_TMP,x
 ;       dex
 ;       bpl -
        jsr SID_INIT
.fi
        cli
        ; Le barre d'espacement
-       lda $dc01
        and #$10
        bne -
        lda #$37
        sta $01
        jmp $fce2
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
        lda #0
        sta $d020
        sta $d021

        jmp deicide
        ;* = $23e8
;        * = $4c00
logo_setup .proc
        ldx #LOGO_WIDTH - 1
-
.for row = 0, row < 4, row += 1
        lda logo_colram + (row * LOGO_WIDTH),x
        sta $d800 + LOGO_OFFSET + (row * 40),x
.next
        dex
        bpl -
        rts
.pend
        * = $2168
deicide
        lda #$b8
        sta $d018
logo_d016
        lda #$18
        sta $d016

        ldx #$16
-       dex
        bne -
        nop
        nop
vsp_idx
        beq +
+
        .fill 20, $e0
        bit $ea

        lda #$39
        ldx #$3b
        sta $d011
        stx $d011

        ;lda #0
        ;sta $d020
.if SID_ENABLE
;        ldx #$0f
;-       lda ZP_TMP,x
;        sta $f0,x
;        dex
;        bpl -

        jsr SID_PLAY

;        ldx #$0f
;-       lda $f0,x
;        sta ZP_TMP,x
;        dex
;        bpl -
.fi
;        dec $d020
        jsr update_fld

;        lda #0
;        sta $d020

        ldy #$32 + 5* 8  - 2
        lda #<irq1
        ldx #>irq1
        jmp do_irq

; Run delay loop decrementing X
;
; Adds 6 for JSR and 6 for the RTS, Z will be 0
delay_with_x .proc
-       dex
        bne -
        rts
.pend
update_fld .proc
        ldx #$30
        cpx #64
        bcc +
        ldx #0
+
        lda vsp_table,x
        sta fld + 1
        inx
+       stx update_fld +1
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
        ldx #4
-       dex
        bne -
        jsr fcps2
;        .fill 12, $ea
       lda fld +1
        clc
        adc #$64
        sta $d009
        sta $d00b
        sta $d00d
        sta $d00f
        adc #32  - 24
        sta $d001
        sta $d003
        sta $d005
        sta $d007
        jsr fld

       lda #$ff
        sta $d015
 
       lda $d011
        and #$1f
        sta $d011

        ldx dycp_scroll + 1

       stx $d016

        lda #6
         ; TODO: good place to do sprite-Y stuff when also doing FLD et
        ldx #$51
-       dex
        bne -
        ldy #$0a
        sty $d018
 
         sta $d021
        sta $d020,x     ; + 1 cycle
 
        


        ;ldx #$08
        ;stx $d016
        ;lda #$08
        ;sta $d018
;;        sta $d020
;        lda #4
;        sta $d020



        ;lda #$1b
        ;sta $d011
        lda #$32+ (6+4) * 8 -1
        clc
        adc fld +1
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
        ldx #5
-       dex
        bne -
        stx $d021
        nop
        nop
        nop
        stx $d020
 
        lda #$7b
        sta $d011

        ldy #$fb
        lda #<irq3
        ldx #>irq3
        jmp do_irq

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
irq3
        pha
        txa
        pha
        tya
        pha
        ldx #$07
-       dex
        bne -
        lda #5
        sta $d020
        sta $d021
;        dec $d020
        jsr dycp_clear
        jsr dycp_update
        jsr dycp_scroll
        jsr dycp_render
        ;jsr handle_delay
        jsr vsp_update
        ;jsr show_delay
 ;       lda #5
 ;       sta $d020

        lda #<irq0
        ldx #>irq0
        ldy #RASTER
        jmp do_irq
        * = $2528

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
        sbc #20
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
row     sta @wDYCP_MATRIX,x
        adc #DYCP_HEIGHT
        inx
        cpx #DYCP_WIDTH
        bne -
        lda row + 1
        adc #39 ; C = 1
        sta row + 1
        bcc +
        inc row +2
+
        iny
        cpy #DYCP_HEIGHT
        bne --  ; C = 0


        ldx #0
        txa
-       sta DYCP_CHARSET,x
        sta DYCP_CHARSET + 256,x
        sta DYCP_CHARSET + 512,x
        inx
        bne -

        ldx #23
-       lda #0
        sta dycp_sinus,x
        sta dycp_text,x
        lda #$0d
        sta $d800 + (DYCP_MATRIX & $03ff),x
        sta $d828 + (DYCP_MATRIX & $03ff),x
        sta $d850 + (DYCP_MATRIX & $03ff),x
        sta $d878 + (DYCP_MATRIX & $03ff),x

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
        sta dycp_sinus,x
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
fcps2
        lda #20
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



dycp_clear .proc
        ldx #0
        stx ZP + 2

        lda #<DYCP_CHARSET
        sta ZP + 0
        lda #>DYCP_CHARSET
        sta ZP + 1
-
        ldy dycp_sinus,x
        lda #0
        ldx #4
-       sta (ZP),y
        iny
        dex
        bpl -

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

        * = $2ce8

sprites_setup .proc
        lda #$ff
        sta $d015
        sta $d01d
        ldx #$3e
        lda #$ff
-       sta FILL_SPRITE,x
        dex
        bpl -
        ldx #7
-       lda #6
        sta $d027,x
        lda #(FILL_SPRITE/64)
        sta $03f8,x
        dex
        bpl -

        lda #$18        ; 3
        sta $d000
        sta $d008
        sta $d00c
        sta $d004

        lda #$30        ; 3
        sta $d00a
        sta $d002
;        lda #$40
        sta $d006
        sta $d00e
        lda #$cc
        sta $d010

        rts
.pend

; colram
;        * = $2e00
logo_colram
.for cram_row = 0, cram_row < 4, cram_row += 1
  .binary "focus.kla", 2 + 9000 + (cram_row * 40) + 0, LOGO_WIDTH
.next

vsp_table
        .byte 56 + 55.5 * sin(range(64) * rad(360.0/64.0))


ytable  .byte 11 + 10.5 * sin(range(48) * rad(360.0/48.0)) + 1


;* = $4800
dycp_render .proc
        ldx #0
        stx ZP + 2
        lda #<DYCP_CHARSET
        sta ZP
        lda #>DYCP_CHARSET
        sta ZP + 1
-
        ldy dycp_sinus,x
        lda dycp_text,x
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

; DYCP scroller, just 256 byte max, we're doing 4KB here :)
dycp_scroll .proc
        lda #0
        sec
        sbc #DYCP_SCROLL_SPEED
        and #07
        sta dycp_scroll +1
        bcc +
        rts
+
        ; move text
        ldx #0
-       lda dycp_text + 1,x
        sta dycp_text + 0 ,x
        inx
        cpx #23
        bne -

txtidx  ldx #0
        lda dycp_scrolltext,x
        bne +
        sta txtidx + 1
+
        asl
        asl
        asl
        sta dycp_text + 23

        inc txtidx + 1
        rts
.pend



        * = $2f00
        FONT = *
.binary "font000.prg", 2


        * = SID_LOAD
.binary format("%s", SID_PATH), $7e


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
.for vram_row = 0, vram_row < 4, vram_row += 1
  .binary "focus.kla", 2 + 8000 + (vram_row * 40) + 0, LOGO_WIDTH
  .fill 40 - LOGO_WIDTH, $00
  ;* += (40 - LOGO_WIDTH)
.next




fld     .proc
        ldx #0
        ldy #0
        clc
-       lda $d012
        adc #1
        and #$07
        ora #$78
        sta $d011,y
        ;sta $d020
;        sta $d020
        dex
        bpl -
        rts
.pend

        * = $4000

; $1b = .
; $1c = ,
; $1d = '
; $1e = + (for cracks)
; $1f = % (for cracks)
dycp_scrolltext
        .enc "screen"
        .text "four kilobytes kinda sucks", $1c
        .text "but i decided to get at least some graphics and lame effects "
        .text "in this", $1b
        .text "  so here we have a bitmap logo vsp and a dycp", $1b
        .text "  ", $1e,$1e,$1e, "focus rules", $1e,$1e,$1e
        .text " ", 0

        .align 256

