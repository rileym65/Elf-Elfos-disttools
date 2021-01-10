; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    bios.inc

#ifdef RAM
boot:      equ     1400h
           org     03400h
#else
boot:      equ     2400h
           org     09400h
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
start:     sep     scall
           dw      f_setbd
           sep     scall               ; call bios to set terminal
           dw      mover
           ldi     high startmsg       ; display the start message
           phi     rf
           ldi     low startmsg
           plo     rf
           sep     scall
           dw      f_msg

           sep     scall               ; perform ide reset
           dw      f_idereset

; ****************************************
; *** Read boot sector to get geometry ***
; ****************************************
           ldi     0                   ; setup to read sector 0
           plo     r7
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
           ldi     high sector         ; point to sector buffer
           phi     rf
           ldi     low sector
           plo     rf
           sep     scall               ; call bios
           dw      f_ideread

; ********************************
; *** Display sectors for disk ***
; ********************************
           ldi     high sectmsg        ; display sector summary
           phi     rf
           ldi     low sectmsg
           plo     rf
           sep     scall
           dw      f_msg
           ldi     high sector        ; display sector summary
           adi     1
           phi     rf
           ldi     0
           plo     rf
           lda     rf                  ; get high word of sector count
           phi     rb
           lda     rf
           plo     rb
           lda     rf                  ; get low word of sector count
           phi     rc
           lda     rf
           plo     rc
 
           ldi     high seccount       ; get boot sector address
           phi     r7
           ldi     low seccount
           plo     r7
           ghi     rb                  ; write sector count to boot sector
           str     r7
           inc     r7
           glo     rb
           str     r7
           inc     r7
           ghi     rc                  ; write lo sector count to boot sector
           phi     r8                  ; make copy in r8
           str     r7
           inc     r7
           glo     rc
           plo     r8
           str     r7
           inc     r7

           ldi     1                   ; file system type number
           str     r7
           inc     r7
           ghi     rc                  ; transfer low word for display
           phi     rf
           glo     rc
           plo     rf
           sep     scall
           dw      intout
           ldi     high crlf
           phi     rf
           ldi     low crlf
           plo     rf
           sep     scall
           dw      f_msg
; ***************************
; *** Set AU size to 8    ***
; ***************************
           ldi     high ausizemsg      ; display sector summary
           phi     rf
           ldi     low ausizemsg
           plo     rf
           sep     scall
           dw      f_msg
           inc     r7                  ; point to alloc size in boot sector
           inc     r7
           inc     r7
           inc     r7
           ldi     0                   ; get 8
           phi     rf
           str     r7                  ; store into boot sector
           inc     r7
           ldi     8
           plo     rf
           str     r7                  ; store into boot sector
           inc     r7
           sep     scall               ; display number
           dw      intout
           ldi     high crlf
           phi     rf
           ldi     low crlf
           plo     rf
           sep     scall
           dw      f_msg

; ******************************
; *** Computer number of AUs ***
; ******************************
           ldi     high aucntmsg       ; display sector summary
           phi     rf
           ldi     low aucntmsg
           plo     rf
           sep     scall
           dw      f_msg
           glo     rb                  ; divide by 2
           shr
           plo     rb
           ghi     rc
           shrc
           phi     rc
           glo     rc
           shrc
           plo     rc
           glo     rb                  ; divide by 4
           shr
           plo     rb
           ghi     rc
           shrc
           phi     rc
           glo     rc
           shrc
           plo     rc
           glo     rb                  ; divide by 8
           shr
           plo     rb
           ghi     rc
           shrc
           phi     rc
           glo     rc
           shrc
           plo     rc

           plo     rf
           ghi     rc                  ; copy for display
           phi     rf
           sep     scall               ; display number
           dw      intout
           ldi     high crlf
           phi     rf
           ldi     low crlf
           plo     rf
           sep     scall
           dw      f_msg
           ghi     rc                  ; write au count to boot sector
           str     r7
           inc     r7
           glo     rc
           str     r7
           inc     r7

; **********************************************
; *** Now to generate the allocation sectors ***
; *** Starting at sector 17                  ***
; **********************************************
           ldi     17                  ; setup LBA addresses
           plo     r7
           ldi     0
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
; ****************************
; *** Generate each sector ***
; ****************************
auseclp:   ldi     high sector         ; point to sector buffer
           phi     rf
           ldi     low sector
           plo     rf
           ldi     0                   ; 256 entries in sector
           plo     rb                  ; put into secondary count
auseclp2:  glo     rc                  ; see if count is zero
           str     r2
           ghi     rc
           or
           lbz     audone              ; all done with AUs,
           ldi     0                   ; indicate available sector
           str     rf
           inc     rf
           str     rf
           inc     rf
           dec     rc                  ; decrement AU count
           dec     rb                  ; decrement AUs in sector count
           glo     rb                  ; get AUs in sector count
           bnz     auseclp2            ; loop until sector is full
; **************************************
; *** Write completed sector to disk ***
; **************************************
           sep     scall               ; call write sector routine
           dw      write
           inc     r7                  ; point to next sector
           lbr     auseclp             ; loop back until done

audone:    glo     rb                  ; was last sector complete
           lbz     noneed              ; no need to complete sector
auseclp3:  ldi     255                 ; indicate unavailable sector
           str     rf
           inc     rf
           str     rf
           inc     rf
           dec     rb                  ; decrement AUs in sector count
           glo     rb                  ; get AUs in sector count
           bnz     auseclp3            ; loop until sector is full
; **************************************
; *** Write completed sector to disk ***
; **************************************
           sep     scall               ; call write sector routine
           dw      write
           inc     r7                  ; point to next sector

noneed:    ldi     0ffh                ; fill sector buffer with unavailable
           sep     scall
           dw      fill
unloop:    glo     r7                  ; is sector buffer on even 8?
           ani     07h
           bz      even8               ; jump if so
           sep     scall               ; write next allocation sector
           dw      write
           inc     r7                  ; increment sector count
           br      unloop              ; loop until on even 8

even8:     ldi     high mdirmsg        ; message for master directory
           phi     rf
           ldi     low mdirmsg
           plo     rf
           sep     scall               ; call bios to display message
           dw      f_msg
           ghi     r7                  ; get directory
           phi     rf
           glo     r7
           plo     rf
           sep     scall               ; display number
           dw      intout
           ldi     high crlf
           phi     rf
           ldi     low crlf
           plo     rf
           sep     scall
           dw      f_msg
           ldi     high masterdir      ; master directory in boot sector
           phi     rf
           ldi     low masterdir
           plo     rf
           ghi     r7                  ; get master dir number
           str     rf                  ; and store into boot sector
           inc     rf
           glo     r7
           str     rf
           inc     rf
           ldi     0                   ; high word is zero
           str     rf
           inc     rf
           str     rf

; **************************************
; *** Now clear the master directory ***
; **************************************
           ldi     0                   ; fill sector buffer with zeroes
           sep     scall
           dw      fill
           glo     r7                  ; save sector number
           stxd
           ghi     r7
           stxd
           ldi     8                   ; 8 sectors to write
           plo     rc
dirloop:   glo     rc                  ; save count
           stxd
           sep     scall               ; call write sector routine
           dw      write
           irx                         ; recover count
           ldx
           plo     rc
           inc     r7                  ; point to next sector
           dec     rc                  ; decrement count
           glo     rc                  ; are we done?
           bnz     dirloop             ; jump if not
           irx                         ; recover sector number
           ldxa
           phi     r7
           ldx
           plo     r7

; *************************************
; *** Now allocate lumps through DM ***
; *************************************
           ghi     r7                  ; divide by 2
           shr
           phi     r7
           glo     r7
           shrc
           plo     r7
           ghi     r7                  ; divide by 4
           shr
           phi     r7
           glo     r7
           shrc
           plo     r7
           ghi     r7                  ; divide by 8
           shr
           phi     r7
           glo     r7
           shrc
           plo     r7
           ldi     high sector         ; get sector buffer
           phi     rf
           ldi     low sector
           plo     rf
aloop1:    ldi     0ffh                ; indicator of allocated sector
           str     rf
           inc     rf
           str     rf
           inc     rf
           dec     r7                  ; decrement count
           glo     r7                  ; check for zero
           bnz     aloop1              ; loop til done
           ldi     high sector         ; get sector buffer
           phi     rf
           ldi     low sector
           plo     rf
           ldi     17                  ; need to rewrite first allocation sec
           plo     r7
           ldi     0
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
           sep     scall               ; write it
           dw      write

; *************************
; *** Build MD entry    ***
; *************************
           ldi     low boot            ; point to sector buffer
           adi     5                   ; add 261 to it
           plo     rf
           ldi     high boot
           adci    1                   ; continue addition of 300
           phi     rf
           lda     rf                  ; get dir sector
           phi     rd
           lda     rf
           plo     rd
           ldi     3                   ; need to loop 3 times
           plo     rc
mdloop:    ghi     rd                  ; divide by 2
           shr
           phi     rd
           glo     rd
           shrc
           plo     rd
           dec     rc                  ; check end of loop
           glo     rc
           bnz     mdloop              ; loop back if not
           glo     rf                  ; add 37 to get to md entry
           adi     37
           plo     rf
           ghi     rf
           adci    0
           phi     rf
           ldi     0                   ; high word of lump
           str     rf
           inc     rf
           str     rf
           inc     rf
           ghi     rd                  ; write starting lump number
           str     rf
           inc     rf
           glo     rd
           str     rf
           inc     rf
           ldi     0                   ; eof byte
           str     rf
           inc     rf
           str     rf
           inc     rf
           ldi     1                   ; set directory flag
           str     rf                  ; flags
           inc     rf
           ldi     0                   ; zero date and time
           str     rf                  ; flags2
           inc     rf
           str     rf                  ; month
           inc     rf
           str     rf                  ; day
           inc     rf
           str     rf                  ; year
           inc     rf
           ldi     'M'                 ; filename
           str     rf
           inc     rf
           ldi     'D'
           str     rf
           inc     rf
           ldi     0
           str     rf
           inc     rf


; *************************
; *** Write boot sector ***
; *************************
           ldi     0                   ; setup to read sector 0
           plo     r7
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
           ldi     high boot           ; point to sector buffer
           phi     rf
           ldi     low boot
           plo     rf
           sep     scall               ; call bios
           dw      f_idewrite

; ****************************************
; *** set proper md eof lump           ***
; ****************************************
           ldi     17                  ; setup to read sector 17
           plo     r7
           ldi     0
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
           ldi     high sector         ; point to sector buffer
           phi     rf
           ldi     low sector
           plo     rf
           sep     scall               ; call bios
           dw      f_ideread
           glo     rd                  ; convert lump to offset
           shl
           plo     rd
           ghi     rd
           shlc
           phi     rd
           glo     rd
           stxd
           irx
           ldi     low sector          ; point to sector buffer
           add
           plo     rf
           ghi     rd
           stxd
           irx
           ldi     high sector
           adc
           phi     rf
           ldi     0feh                ; code for eof lump
           str     rf
           inc     rf
           str     rf
           ldi     17                  ; setup to write sector 17
           plo     r7
           ldi     0
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
           ldi     high sector         ; point to sector buffer
           phi     rf
           ldi     low sector
           plo     rf
           sep     scall               ; call bios
           dw      f_idewrite
 

           ldi     high donemsg        ; display the start message
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

; ****************************
; *** Write sector to disk ***
; ****************************
write:     ghi     r7                  ; save R7
           stxd
           glo     r7
           stxd
           ghi     r8                  ; save R8
           stxd
           glo     r8
           stxd
           ghi     rc                  ; save RC
           stxd
           glo     rc
           stxd
           ldi     high sector         ; point to sector buffer
           phi     rf
           ldi     low sector
           plo     rf
           sep     scall               ; call bios to write sector
           dw      f_idewrite
           irx
           ldxa                        ; recover RC
           plo     rc
           ldxa
           phi     rc
           ldxa                        ; recover R8
           plo     r8
           ldxa
           phi     r8
           ldxa                        ; recover R7
           plo     r7
           ldx
           phi     r7
           sep     sret                ; return to caller
 



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

intout:    sex     r2
           ldi     27h                 ; hi byte of 10000
           phi     rd                  ; place into subtraction
           ldi     10h                 ; lo byte of 10000
           plo     rd
           ldi     0                   ; leading zero flag
           stxd                        ; store onto stack
nxtiter:   ldi     0                   ; star count at zero
           plo     ra                  ; place into low of r8
divlp:     glo     rd                  ; get low of number to subtrace
           str     r2                  ; place into memory
           glo     rf                  ; get low of number
           sm                          ; subtract
           phi     ra                  ; place into temp space
           ghi     rd                  ; get high of subtraction
           str     r2                  ; place into memory
           ghi     rf                  ; get high of number
           smb                         ; perform subtract
           bnf     nomore              ; jump if subtraction was too large
           phi     rf                  ; store result
           ghi     ra
           plo     rf
           inc     ra                  ; increment count
           br      divlp               ; and loop back
nomore:    irx                         ; point back to leading zero flag
           glo     ra
           bnz     nonzero             ; jump if not zero
           ldn     r2                  ; get flag
           bnz     allow0              ; jump if no longer zero
           dec     r2                  ; keep leading zero flag
           br      findnxt             ; skip output
allow0:    ldi     0                   ; recover the zero
nonzero:   adi     30h                 ; convert to ascii
           sep     scall
           dw      f_type
           ldi     1                   ; need to set leading flag
           stxd                        ; store it
findnxt:   ghi     rd                  ; get high from subtraction byte
           smi     27h                 ; check for 10000
           bnz     not10000            ; jump if not
           ldi     3                   ; high byte of 1000
           phi     rd                  ; place into r7
           ldi     0e8h                ; low byte of 1000
           plo     rd                  ; plate into r7
           br      nxtiter             ; perform next iteration
not10000:  ghi     rd                  ; get high byte of subtraction
           smi     3                   ; check for 1000
           bnz     not1000             ; jump if not
           ldi     0                   ; high byte of 100
           phi     rd                  ; place into r7
           ldi     100                 ; low byte of 100
           plo     rd                  ; plate into r7
           br      nxtiter             ; perform next iteration
not1000:   glo     rd                  ; get byte from subtraction
           smi     100                 ; check for 100
           bnz     not100              ; jump if not 100
           ldi     0                   ; high byte of 10
           phi     rd                  ; place into r7
           ldi     10                  ; low byte of 10
           plo     rd                  ; plate into r7
           br      nxtiter             ; perform next iteration
not100:    glo     rd                  ; get byte from subtraction
           smi     10                  ; check for 10
           bnz     intdone             ; jump if done
           irx
           ldi 1
           stxd
           ldi     0                   ; high byte of 1
           phi     rd                  ; place into r7
           ldi     1                   ; low byte of 1
           plo     rd                  ; plate into r7
           br      nxtiter             ; perform next iteration
intdone:   irx                         ; put x back where it belongs
           sep     sret                ; return to caller

mover:     ldi     high bootcode
           phi     r8
           ldi     low bootcode
           plo     r8
           ldi     high boot
           phi     r9
           ldi     low boot
           plo     r9
           ldi     255
           plo     rc
movelp:    lda     r8
           str     r9
           inc     r9
           dec     rc
           glo     rc
           lbnz     movelp
           sep     sret
           
startmsg:  db      'IDE File System Gen Utility',10,13
crlf:      db      10,13,0
sectmsg:   db      'Total Sectors: ',0
ausizemsg: db      'AU Size: ',0
aucntmsg:  db      'Total AUs: ',0
mdirmsg:   db      'Master Dir Sector: ',0
donemsg:   db      'File system generation complete',10,13,0

#ifdef RAM
           org     03800h
#else
           org     09800h
#endif
;          org     2400h
; ************************************
; *** Define disk boot sector      ***
; *** This runs at 100h            ***
; *** Expects to be called with R0 ***
; ************************************
bootcode:  ghi     r0                  ; get current page
           phi     r3                  ; place into r3
           ldi     low bootst          ; boot start code
           plo     r3
           sep     r3                  ; transfer control
bootst:    ldi     high call           ; setup call vector
           phi     r4
           ldi     low call
           plo     r4
           ldi     high ret            ; setup return vector
           phi     r5
           ldi     low ret
           plo     r5
           ldi     0                   ; setup an initial stack
           phi     r2
           ldi     0f0h
           plo     r2
           ldi     1                   ; setup sector address
           plo     r7
           ldi     3                   ; starting page for kernel
           phi     rf                  ; place into read pointer
           ldi     0
           plo     rf
           sex     r2                  ; set stack pointer
bootrd:    glo     r7                  ; save R7
           str     r2
           out     4
           dec     r2
           stxd
           ldi     0                   ; prepare other registers
           phi     r7
           plo     r8
           ldi     0e0h
           phi     r8
           sep     scall               ; call bios to read sector
           dw      f_ideread
           irx                         ; recover R7
           ldxa
           plo     r7
           inc     r7                  ; point to next sector
           glo     r7                  ; get count
           smi     15                  ; was last sector (16) read?
           bnz     bootrd              ; jump if not
           ldi     3                   ; setup jump to os
           phi     r0
           ldi     0
           plo     r0
           sep     r0                  ; jump to os

#ifdef RAM
           org     1500h
#else
           org     2500h
#endif

seccount:  dw      0,0
fstype:    db      0
masterdir: dw      0,0
allocsize: dw      0
aucount:   dw      0,0

#ifdef RAM
           org     1600h
#else
           org     2600h
#endif

sector:    ds      256

