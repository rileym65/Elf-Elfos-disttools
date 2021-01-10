; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    bios.inc
include    kernel.inc

#ifdef RAM
fildes:    equ     5000h
table:     equ     2003h
           org     3a00h
#else
fildes:    equ     2000h
table:     equ     8003h
           org     9a00h
#endif

boot:      ldi     0                   ; setup stack
           phi     r2
           ldi     0f0h
           plo     r2
           sex     r2
           ldi     high start          ; setup for start
           phi     r6
           ldi     low start
           plo     r6
           lbr     f_initcall          ; setup linkage registers
start:     sep     scall
           dw      f_setbd

           sep     scall
           dw      f_idereset
           ldi     high msg
           phi     rf
           ldi     low msg
           plo     rf
           sep     scall
           dw      f_msg

#ifdef RAM
           ldi     043h                ; source position for kernel
#else
           ldi     0a3h                ; source position for kernel
#endif
           phi     r9
           ldi     03h                 ; destination for kernel
           phi     r8
           ldi     0
           plo     r9
           plo     r8
           plo     rc
#ifdef RAM
           ldi     01ch                ; will copy 7k
#else
           ldi     020h                ; will copy 7k
#endif
           phi     rc
krnllp:    lda     r9                  ; get source byte
           str     r8                  ; store into destination
           inc     r8
           dec     rc                  ; decrement the count
           glo     rc                  ; check if done
           bnz     krnllp              ; loop back if not
           ghi     rc
           bnz     krnllp

           sep     scall               ; setup kernel
           dw      o_lmpsize

           ldi     high bindir         ; want to make BIN directory
           phi     rf
           ldi     low bindir
           plo     rf
           sep     scall
           dw      o_mkdir

           ldi     high bindir         ; want to make BIN directory
           phi     rf
           ldi     low bindir
           plo     rf
           ldi     0
           phi     rd
           ldi     40h
           plo     rd
binlp:     lda     rf
           str     rd
           inc     rd
           bnz     binlp
           ldi     0
           phi     rf
           ldi     40h
           plo     rf

           sep     scall
           dw      o_chdir
           
           ldi     high fildes         ; need to setup file descriptor
           phi     rf
           ldi     low fildes
           plo     rf
           inc     rf                  ; point to dta entry
           inc     rf
           inc     rf
           inc     rf
           ldi     021h                ; setup dta
           str     rf
           inc     rf
           ldi     0
           str     rf

           ldi     high table          ; point to utils table
           phi     ra
           ldi     low table
           plo     ra
mainlp:    ldn     ra                  ; get byte from tale
           lbz     maindone            ; jump if done
           sep     scall               ; call for entry
           dw      entry
mainlp2:   lda     ra                  ; get byte from entry
           bnz     mainlp2             ; loop until zero found
           glo     ra                  ; point to next entry
           adi     10
           plo     ra
           ghi     ra
           adci    0
           phi     ra
           br      mainlp              ; and loop back for next entry

entry:     ldi     high instmsg        ; point to message
           phi     rf
           ldi     low instmsg
           plo     rf
           sep     scall               ; and display it
           dw      f_msg
           glo     ra                  ; save entry address
           plo     rf                  ; and put copy in rf
           stxd
           ghi     ra
           phi     rf
           stxd
           sep     scall               ; display filename
           dw      f_msg
           ldi     high inst2msg       ; point to message
           phi     rf
           ldi     low inst2msg
           plo     rf
           sep     scall               ; and display it
           dw      f_msg
           sep     scall               ; get key from user
           dw      f_read
           plo     re                  ; save a copy
           smi     'Y'                 ; check against upper case y
           lbz     entryyes            ; jump if yes
           glo     re                  ; retrieve copy
           smi     'y'                 ; check against lower case y
           lbz     entryyes            ; jump if yes
           lbr     entryno             ; jump if anything else

entryyes:  ldi     high instalmsg      ; display skipped message
           phi     rf
           ldi     low instalmsg
           plo     rf
           sep     scall
           dw      f_msg
           ghi     ra                  ; transfer filename
           phi     rf
           glo     ra
           plo     rf
           ldi     high fildes         ; get file descriptor
           phi     rd
           ldi     low fildes
           plo     rd
           ldi     1                   ; create if it does not exist
           plo     r7
           sep     scall               ; open/create the file
           dw      o_open
entry1:    lda     ra                  ; move past filename
           bnz     entry1
           glo     ra                  ; put execution header address in rf
           adi     4
           plo     rf
           ghi     ra
           adci    0
           phi     rf
           ldi     0                   ; 6 bytes in header
           phi     rc
           ldi     6
           plo     rc
           sep     scall               ; write the header
           dw      o_write
           lda     ra                  ; get rom start address
           phi     rf                  ; and place into rf
           stxd                        ; into memory as well
           lda     ra
           plo     rf
           str     r2                  ; into memory as well
           inc     ra                  ; point to low byte of end
           ldn     ra                  ; get it 
           sm                          ; subtract start
           plo     rc                  ; and place into count
           irx                         ; point to high byte
           dec     ra
           ldn     ra
           smb
           phi     rc
           sep     scall               ; write block to file
           dw      o_write
close:     sep     scall               ; close the file
           dw      o_close
           lbr     entrydn

entryno:   ldi     high skipped        ; display skipped message
           phi     rf
           ldi     low skipped
           plo     rf
           sep     scall
           dw      f_msg
entrydn:   irx                         ; recover pointer
           ldxa
           phi     ra
           ldx
           plo     ra
           sep     sret                ; and return to caller

#ifdef RAM
maindone:  lbr     3013h               ; return to installation menu
#else
maindone:  lbr     9013h               ; return to installation menu
#endif

msg:       db     'Binary utilities installer'
crlf:      db     10,13,0
instmsg:   db     'Install ',0
inst2msg:  db     ' ? ',0
skipped:   db     ' Skipped',10,13,0
instalmsg: db     ' Installing...',10,13,0
bindir:    db     '/BIN',0


