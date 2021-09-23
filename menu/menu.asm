; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    bios.inc

#define EOSINST 9013h
#define GOSEDIT 0d809h

buffer:    equ     07f00h

           org     0d000h
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
main:      sep     scall             ; clear screen
           dw      f_inmsg
           db      27,'[H',27,'[2J',0
           mov     rd,04b17h         ; set screen position
           sep     scall
           dw      gotoxy
           sep     scall             ; display version
           dw      f_inmsg
           db      'v4.1',0
           mov     rd,02004h         ; set screen position
           sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; display banner
           dw      f_inmsg
           db      'Pico/Elf V2 Elf/OS',0
           mov     rd,02006h         ; set position
           sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; display menu item
           dw      f_inmsg
           db      '1. Install Elf/OS',0
           inc     rd                ; next row
           sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; display menu item
           dw      f_inmsg
           db      '2. Run SEDIT',0
           inc     rd                ; next row
           sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; display menu item
           dw      f_inmsg
           db      '3. Boot Elf/OS',0
           inc     rd                ; next row
           inc     rd                ; next row
           ghi     rd                ; get x
           adi     3                 ; add 3
           phi     rd                ; put it back
           sep     scall             ; set cursor position
           dw      gotoxy
           sep     scall             ; show prompt
           dw      f_inmsg
           db      'Option ? ',0
           mov     rf,buffer         ; use lowest memory for input buffer
           sep     scall             ; get input from user
           dw      f_input
           mov     rf,buffer         ; point to buffer
           ldn     rf                ; get input
           smi     '1'               ; check option 1
           lbz     EOSINST           ; jump to Elf/OS installer
           ldn     rf                ; get input
           smi     '2'               ; check option 2
           lbz     runsedit          ; jump to SEDIT
           ldn     rf                ; get input
           smi     '3'               ; check option 3
           lbz     bootsys           ; boot IDE

           lbr     main

runsedit:  ldi     0ch
           sep     scall
           dw      f_type
           lbr     GOSEDIT

bootsys:   ldi     0ch               ; clear the screen
           sep     scall
           dw      f_type
           sep     scall             ; display booting message
           dw      f_inmsg
           db      'Booting sytem... ',10,13,
           db      'Wait several seconds and then press'
           db      ' <ENTER> for auto-baud detect',10,13,10,13,0
           lbr     0ff00h





; *********************************************************
; ***** Takes value in D and makes 2 char ascii in RF *****
; *********************************************************
itoa:      plo     rf                ; save value
           ldi     0                 ; clear high byte
           phi     rf
           glo     rf                ; recover low
itoalp:    smi     10                ; see if greater than 10
           lbnf    itoadn            ; jump if not
           plo     rf                ; store new value
           ghi     rf                ; get high character
           adi     1                 ; add 1
           phi     rf                ; and put it back
           glo     rf                ; retrieve low character
           lbr     itoalp            ; and keep processing
itoadn:    glo     rf                ; get low character
           adi     030h              ; convert to ascii
           plo     rf                ; put it back
           ghi     rf                ; get high character
           adi     030h              ; convert to ascii
           phi     rf                ; put it back
           sep     sret              ; return to caller
; *********************************************
; ***** Send vt100 sequence to set cursor *****
; ***** RD.0 = y                          *****
; ***** RD.1 = x                          *****
; *********************************************
gotoxy:    ldi     27                ; escape character
           sep     scall             ; write it
           dw      f_type
           ldi     '['               ; square bracket
           sep     scall             ; write it
           dw      f_type
           glo     rd                ; get x
           sep     scall             ; convert to ascii
           dw      itoa
           ghi     rf                ; high character
           sep     scall             ; write it
           dw      f_type
           glo     rf                ; low character
           sep     scall             ; write it
           dw      f_type
           ldi     ';'               ; need separator
           sep     scall             ; write it
           dw      f_type
           ghi     rd                ; get y
           sep     scall             ; convert to ascii
           dw      itoa
           ghi     rf                ; high character
           sep     scall             ; write it
           dw      f_type
           glo     rf                ; low character
           sep     scall             ; write it
           dw      f_type
           ldi     'H'               ; need terminator for position
           sep     scall             ; write it
           dw      f_type
           sep     sret              ; return to caller

menu:      db      10,13,10,13,'Elf/Os Installation',10,13,10,13
           db      '1> Run hard drive init tool',10,13
           db      '2> Run filesystem gen tool',10,13
           db      '3> Run sys tool',10,13
           db      '4> Install binaries',10,13
           db      '5> Boot Elf/OS',10,13,10,13
           db      '   Option ? ',0

