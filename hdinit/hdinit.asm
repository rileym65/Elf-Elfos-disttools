; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    bios.inc

#ifdef RAM
           org     03200h
#else
           org     09200h
#endif

           ldi     0                   ; setup stack
           phi     r2
           ldi     0ffh       
           plo     r2
           sex     r2                  ; point x to stack
           ldi     high start          ; get main start address
           phi     r6                  ; and place into standard PC
           ldi     low start
           plo     r6
           lbr     f_initcall
start:     sep     scall               ; call bios to set terminal
           dw      f_setbd
           ldi     high startmsg       ; display the start message
           phi     rf
           ldi     low startmsg
           plo     rf
           sep     scall
           dw      f_msg

           ldi     0                   ; master drive
           plo     rd
           sep     scall               ; perform ide reset
           dw      f_idereset

redo:      ldi     high typemsg        ; display type message
           phi     rf
           ldi     low typemsg
           plo     rf
           sep     scall               ; display it
           dw      f_msg
           sep     scall               ; read a key
           dw      f_read
           plo     ra                  ; save it

           ldi     high crlf           ; display type message
           phi     rf
           ldi     low crlf
           plo     rf
           sep     scall               ; display it
           dw      f_msg
           glo     ra                  ; get key
           smi     70                  ; check for full
           bz      full                ; jump if so
           smi     11                  ; check for quick
           lbz     quick
           smi     21                  ; check lowercase full
           bz      full
           smi     11                  ; check lowercase quick
           lbz     quick
           br      redo

full:      ldi     00                  ; want to write zero to sectors
           sep     scall               ; call fill sector routine
           dw      fill

; **************************
; *** Setup start of LBA ***
; **************************
           ldi     0                   ; start count at sector 0
           plo     r7
           phi     r7
           plo     r8
           ldi     0e0h                ; select LBA mode and drive 0
           phi     r8
           ldi     1
           phi     r9
           ldi     1
           plo     r9
           sex     r2                  ; set stack poitner
formatlp:  glo     r7                  ; save R7
           stxd
           ghi     r7
           stxd
           glo     r8                  ; save R8
           stxd
           ghi     r8
           stxd
           ldi     high sector         ; get sector buffer
           phi     rf
           ldi     low sector
           plo     rf
           sep     scall               ; call bios to write sector
           dw      f_idewrite
           irx
           ldxa                        ; recover R8
           phi     r8
           ldxa
           plo     r8
           ldxa                        ; recover R7
           phi     r7
           ldx
           plo     r7
           shlc                        ; get error status
           stxd                        ; and save
 
           dec     r9                  ; check for 256 sectors done
           glo     r9
           str     r2
           ghi     r9
           or
           bnz     nodisp

           ldi     13                  ; display count
           sep     scall
           dw      f_type
           ghi     r7
           phi     rd
           glo     r7
           plo     rd
           sep     scall
           dw      intout
           ldi     1
           phi     r9
           ldi     0
           plo     r9

nodisp:    irx                         ; recover D
           ldx
           shr
           bdf     cleardn             ; jump if done clearing secotrs
           inc     r7                  ; increment count
           glo     r7
           bnz     formatlp
           ghi     r7
           bnz     formatlp
           inc     r8                  ; carry into next word

           glo     r8
           bnz     formatlp
           ghi     r8
           bnz     formatlp

           ldi     'E'
           sep     scall
           dw      f_type
         idl
cleardn:   ldi     high sectmsg        ; display sector summary
           phi     rf
           ldi     low sectmsg
           plo     rf
           sep     scall
           dw      f_msg
           ghi     r7
           phi     rd
           glo     r7
           plo     rd
           sep     scall
           dw      intout
           ldi     high crlf
           phi     rf
           ldi     low crlf
           plo     rf
           sep     scall
           dw      f_msg

           ldi     0                   ; master drive
           plo     rd
           sep     scall               ; perform ide reset
           dw      f_idereset

; *******************************************
; *** Write sector count into boot sector ***
; *******************************************
           ldi     high sector         ; point to sector buffer
           adi     1                   ; move up by 256 bytes
           phi     rf
           ldi     low sector
           plo     rf
           ldi     0                   ; write sector count
           str     rf
           inc     rf
           glo     r8
           str     rf
           inc     rf
           ghi     r7
           str     rf
           inc     rf
           glo     r7
           str     rf
           ldi     0                   ; select sector 0
           plo     r7
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
           ldi     high sector         ; point to sector buffer
           phi     rf
           ldi     low sector
           plo     rf
           sep     scall               ; call bios to write sector
           dw      f_idewrite

           ldi     high donemsg        ; display finished message
           phi     rf
           ldi     low donemsg
           plo     rf
           sep     scall
           dw      f_msg

#ifdef RAM
           lbr     3013h
#else
           lbr     9013h
#endif

fill:      stxd                        ; save D
           ldi     2                   ; high byte of 512
           phi     rc
           ldi     0
           plo     rc
           ldi     high sector
           phi     rf
           ldi     low sector
           plo     rf
filllp:    irx                         ; recover d
           ldx
           str     rf                  ; store into buffer
           inc     rf
           stxd                        ; save D
           dec     rc                  ; decrement count
           glo     rc                  ; check for zero
           bnz     filllp              ; loop if not
           ghi     rc                  ; check high byte as well
           bnz     filllp
           irx                         ; remove D from stack
           sep     sret                ; and return

intout:    sex     r2                  ; be sure X points to stack
           ldi     0                   ; set up buffer
           phi     rf
           plo     rf
           sep     scall               ; convert number
           dw      f_uintout
           ldi     0                   ; set up buffer
           str     rf                  ; place terminator
           phi     rf
           plo     rf
           sep     scall               ; display number
           dw      f_msg
           sep     sret                ; return to caller
    
quick:     ldi     high sector         ; point to sector buffer
           phi     rf
           ldi     low sector
           plo     rf
           sep     scall               ; read ide id dta
           dw      readid
           ldi     high sector         ; point to sector data
           phi     rf
           ldi     120                 ; start of sector count
           plo     rf
           lda     rf                  ; get sector count
           plo     r7
           lda     rf
           phi     r7
           lda     rf
           plo     r8
           lda     rf
           phi     r8
           lbr     cleardn             ; complete init function

readid:    ldi   high waitrdy          ; get address of subs
           phi   rc
           ldi   low waitrdy
           plo   rc
           sex   r2                    ; be sure X points to stack
           mark                        ; save current P and X
           sep   rc                    ; call wait for RDY routine
           dec   r2                    ; compensate for RET instruction
           ldi   0ech                  ; command to read configuration
           mark                        ; save current P and X
           sep   rc                    ; call command sequence
           dec   r2                    ; compensate for RET instructino
           ldi   2                     ; high byte of 512
           phi   r7                    ; store into counter
           ldi   0                     ; lo byte of 512
           plo   r7                    ; put into low of count
           str   r2                    ; store into memory
           out   2                     ; select data register
           dec   r2                    ; move pointer back
           sex   rf                    ; set data pointer
rdloop:    inp   3                     ; read from ide controller
           inc   rf                    ; point to next position
           dec   r7                    ; decrement byte count
           glo   r7                    ; see if all bytes read
           bnz   rdloop                ; loop back if not
           ghi   r7                    ; check high byte as well
           bnz   rdloop
           adi   0                     ; signify read completed
           sex   r2                    ; restore X pointer
           sep     sret                ; and return to caller
beforerdy: irx                         ; move pointer to SAV location
           ret                         ; and return to caller
waitrdy:   sex     r2                  ; be sure X points to stack
           ldi     07h                 ; need status register
           str     r2                  ; store onto stack
           out     2                   ; write ide selection port
           dec     r2                  ; point x back to free spot
rdyloop:   inp     3                   ; read status port
           ani     0c0h                ; mask for BSY and RDY
           smi     040h                ; want only RDY bit
           bnz     rdyloop             ; loop back until drive is ready
           ldn     r2                  ; get status byte
           irx                         ; move pointer to SAV location
           ret                         ; and return to caller
wrtcmd:    sex     r2                  ; be sure X points to stack
           stxd                        ; write command to memory
           ldi     7                   ; command register
           str     r2                  ; store for outs
           out     2                   ; select IDE register
           out     3                   ; send command
           dec     r2                  ; move pointer back
drqloop:   inp     3                   ; read status register
           ani     8                   ; mask for DRQ bit
           bz      drqloop             ; loop until found
           br      beforerdy           ; return, readying waitrdy again


startmsg:  db      'IDE Disk Initialization Utility',10,13
           db      'formating...',10,13,0
crlf:      db      10,13,0
sectmsg:   db      10,13,'Sectors: ',0
donemsg:   db      10,13,'Complete',10,13,0
typemsg:   db      '<Q>uick or <F>ull ? ',0

#ifdef RAM
           org     1000h
#else
           org     2400h
#endif

sector:    ds      256

