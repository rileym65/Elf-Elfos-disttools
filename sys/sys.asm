; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    bios.inc

#ifdef RAM
           org     3900h
#else
           org     9900h
#endif

; ************************************
; *** Define disk boot sector      ***
; *** This runs at 100h            ***
; *** Expects to be called with R0 ***
; ************************************
boot:      ldi     0                   ; setup stack
           phi     r2
           ldi     0ffh
           plo     r2
           sex     r2
           ldi     high bootst         ; setup for start
           phi     r6
           ldi     low bootst
           plo     r6
           lbr     f_initcall          ; setup linkage registers
bootst:    sep     scall
           dw      f_setbd
           sep     scall
           dw      f_idereset
           ldi     1                   ; setup sector address
           plo     r7
#ifdef RAM
           ldi     043h                ; starting page for kernel
#else
           ldi     0a3h                ; starting page for kernel
#endif
           phi     rf                  ; place into read pointer
           ldi     0
           plo     rf
           sex     r2                  ; set stack pointer
bootrd:    glo     r7                  ; save R7
           stxd
           ldi     0                   ; prepare other registers
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
           sep     scall               ; call bios to write sector
           dw      f_idewrite
           irx                         ; recover R7
           ldx
           plo     r7
           inc     r7                  ; point to next sector
           glo     r7                  ; get count
           smi     17                  ; was last sector (16) written?
           bnz     bootrd              ; jump if not
           ldi     high donemsg
           phi     rf
           ldi     low donemsg
           plo     rf
           sep     scall
           dw      f_msg

#ifdef RAM
           lbr     3013h
#else
           lbr     9013h               ; return to installation menu
#endif

donemsg:   db     'System copied.',10,13,0

