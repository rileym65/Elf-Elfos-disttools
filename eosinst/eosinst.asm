; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    bios.inc

#ifdef RAM
           org     3000h
#else
           org     9000h
#endif
           ldi     01fh                ; setup a stack
           phi     r2
           ldi     0ffh
           plo     r2
           sex     r2
           ldi     high start          ; setup program start
           phi     r6
           ldi     low start
           plo     r6
           lbr     f_initcall          ; setup linking registers
start:     sep     scall               ; setup terminal baud
           dw      f_setbd
main:      ldi     01fh                ; setup a stack
           phi     r2
           ldi     0ffh
           plo     r2
           sex     r2
           ldi     high menu           ; get menu address
           phi     rf
           ldi     low menu
           plo     rf
           sep     scall               ; display it
           dw      f_msg
           ldi     0                   ; setup input buffer
           phi     rf
           plo     rf
           sep     scall               ; get input from user
           dw      f_input
           ldi     0                   ; point back to beginning of buffer
           phi     rf
           plo     rf
           ldn     rf                  ; get byte
           smi     '1'                 ; check for hdinit
           bnz     not1                ; jump if not
#ifdef RAM
           lbr     03213h              ; jump to hdinit routine
not1:      smi     1                   ; check for fsgen
           bnz     not2                ; jump if not
           lbr     03413h              ; jump into fsgen
not2:      smi     1                   ; check for sys
           bnz     not3                ; jump if not
           lbr     03913h              ; jump to sys routine
not3:      smi     1                   ; check for utilities
           bnz     not4                ; jump if not
           lbr     03a13h              ; jump to utilities installer
#else
           lbr     09213h              ; jump to hdinit routine
not1:      smi     1                   ; check for fsgen
           bnz     not2                ; jump if not
           lbr     09413h              ; jump into fsgen
not2:      smi     1                   ; check for sys
           bnz     not3                ; jump if not
           lbr     09913h              ; jump to sys routine
not3:      smi     1                   ; check for utilities
           bnz     not4                ; jump if not
           lbr     09a13h              ; jump to utilities installer
#endif
not4:      smi     1                   ; check for boot
           bnz     main
           lbr     0ff00h              ; boot elfos

menu:      db      10,13,10,13,'Elf/Os Installation',10,13,10,13
           db      '1> Run hard drive init tool',10,13
           db      '2> Run filesystem gen tool',10,13
           db      '3> Run sys tool',10,13
           db      '4> Install binaries',10,13
           db      '5> Boot Elf/OS',10,13,10,13
           db      '   Option ? ',0

