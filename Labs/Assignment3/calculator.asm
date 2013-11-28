; Author: Shivanshu Goyal
; Student Number: 33245127
;
;---------------------------------------------------
; Initializes the switches and Hex displays.
;---------------------------------------------------
PortA	equ	$00400000
PortB	equ	$00400002
PortC	equ	$00400004
PortD	equ	$00400006
HEXA	equ	$00400010
HEXB	equ	$00400012
HEXC	equ	$00400014
HEXD	equ	$00400016
;---------------------------------------------------
; Defines variables
;---------------------------------------------------
	org	$10000	;set the start address
x          ds.l          1
y          ds.l          1
bcd	ds.b	5
counter    ds.l	1
tempx   ds.l	1
tempy   ds.l	1
addIndi    ds.l	1
subIndi    ds.l	1
mulIndi    ds.l	1
divIndi    ds.l	1
switchvalue ds.l	1
	org	$00800000
	jmp myprogram
           ; Load the library of 32-bit operations
           include math32_68k.asm
;----------------------------------------------------------------------
; This subroutine reads the switches in port A and B and combines them
; into a word.  It is used by get_switch below.
;----------------------------------------------------------------------
portAB_to_d1
	move.l #0, d1
	move.b portB, d1
	andi.w  #$ffef, sr ; clear X flag
	roxl.w #8, d1
	move.b portA, d1
	ori.l #$10000, d1 ; Sets the end bit
	rts
;----------------------------------------------------------------------
; This subroutine checks the toggle switches and returns the number of
; of the first one that is toggled up (1).  For example if SW7 is toggle
; up/down, this subroutine returns 7 in d0.  If no switches are toggled,
; 16 is returned.
;----------------------------------------------------------------------
get_switch
           jsr portAB_to_d1
           move.l d1, d2
           ; A bit of debouncing
           move.l #31250,d0	; load d0 with a big number
get_switch_loop
 	subq.l #1,d0		; decrement d0
	bne    get_switch_loop		; keep decrementing until d0 = 0
           jsr portAB_to_d1
           cmp    d1, d2
           beq    get_switch_good      ; If we got the same value after two reads -> good!
           move.l #16, d0
           rts
get_switch_good
           move.l #0,d0
get_switch_next
           btst d0,d1
           bne get_switch_done
           addi.l #1,d0
           bra get_switch_next
           rts
get_switch_done
           jsr portAB_to_d1
           andi.l #$ffff, d1 ; Mask off the end bit
           btst d0,d1
           bne get_switch_done ; Wait until the switch is set back to zero
           rts
;----------------------------------------------------------------------
; Takes the eight least significant bits of 'bcd' and sends them to the
; seven segment displays.
;----------------------------------------------------------------------
display_bcd
	lea.l   bcd, a0
	move.b (a0)+,HEXA
	move.b (a0)+,HEXB
	move.b (a0)+,HEXC
	move.b (a0)+,HEXD
	rts
;----------------------------------------------------------------------
; inserts a bcd digit into bcd by shifting it left one digit.  The two
; most signifcant digits are set to zero because there are only eight
; displays.
;----------------------------------------------------------------------
insert_bcd_digit
           move.l #4,d2
insert_bcd_digit_loop
           lea.l bcd, a0
        	andi.w  #$ffef,  sr     ; clear X flag
        	; Bcd digits 0 and 1
	move.b (A0), d1
	roxl.b  #1,d1
	move.b d1, (a0)+
        	; Bcd digits 2 and 3
	move.b (A0), d1
	roxl.b  #1,d1
	move.b d1, (a0)+
        	; Bcd digits 4 and 5
	move.b (A0), d1
	roxl.b  #1,d1
	move.b d1, (a0)+
        	; Bcd digits 6 and 7
	move.b (A0), d1
	roxl.b  #1,d1
	move.b d1, (a0)+
        	; Bcd digits 8 and 9 have not space.  Set them to zero.
	move.b  #0,d1
	move.b d1, (a0)
	subq.l  #1,d2	; decrement d2
	bne     insert_bcd_digit_loop		; keep decrementing until d2 = 0
	; Insert the new digit
	lea.l   bcd, a0
	or.b    d0,(a0)
	rts
;-------------------------------------------------------
; It reads the switches 8 times, for 8 numbers
;-------------------------------------------------------
inputnumbers
       move.l #8, counter ; sets counter
       clr d0
getnumber
           jsr     get_switch
           cmp.b   #15, d0
           bgt     getnumber
           ; A new number was keyed in
           jsr     insert_bcd_digit
           jsr     display_bcd
           subq.l  #1, counter ; decrements until zero
           bne     getnumber ; jumps if it is zero
           rts
;------------------------------------------------------
; waits approximately 1 sec
;------------------------------------------------------
wait1sec
     move.b #76, d2
L3:  move.b #150, d1
L2:  move.b #250, d0
L1:  subq.l #1, d0
     bne L1
     subq.l #1, d1
     bne L2
     subq.l #1, d2
     bne L3
     rts
;-----------------------------------------------------
; Checks for the operation that you wanted to do
; depending on the switches
;-----------------------------------------------------
waitforoperation
;-----------------------------------------------------
; Each sub-routine checks for switches 15-10, excluding
; switch 11, and loops until one of the switches are
; toggled
;-----------------------------------------------------
       jsr      get_switch
check_add_switch
       move.l   d0, switchvalue
       sub.l    #15, switchvalue
       bne      check_sub_switch
       jmp 	 addit
check_sub_switch
       move.l   d0, switchvalue
       sub.l    #14, switchvalue
       bne      check_mul_switch
       jmp 	 minusit
check_mul_switch
       move.l   d0, switchvalue
       sub.l    #13, switchvalue
       bne      check_div_switch
       jmp 	 mulit
check_div_switch
       move.l   d0, switchvalue
       sub.l    #12, switchvalue
       bne      check_done_switch
       jmp 	 divit
check_done_switch
       sub.l	 #10, switchvalue
       bne      waitforoperation
       jmp      calculator
;----------------------------------------------------
; Depending on which switch is initialized,
; it jumps to whichever the operation.
; It then initializes an indicator to
; to remember which operation it was.
; --------------------------------------------------
addit
    move.l #1, addIndi
    rts
minusit
    move.l #1, subIndi
    rts
mulit
    move.l #1, mulIndi
    rts
divit
    move.l #1, divIndi
    rts
;--------------------------------------------------
; It checks which operation was initialized
; back when the switches were read.
; Depending on which one it is,
; it does the operation.
;--------------------------------------------------
checkoperation
check_add
      cmp.l #0, addIndi
      bne goadd
      jmp check_sub
check_sub
      cmp.l #0, subIndi
      bne gominus
      jmp check_mul
check_mul
      cmp.l #0, mulIndi
      bne gomul
      jmp check_div
check_div
      cmp.l #0, divIndi
      bne godiv
      jmp checkoperation
;---------------------------------------------------
; It does the operation depending on which operation
; it uses math32.asm and actually does the operation
;---------------------------------------------------
goadd
     jsr add32
     rts
gominus
     jsr sub32
     rts
gomul
     jsr mul32
     rts
godiv
     jsr div32
     rts
;--------------------------------------------------
; waits for the equals switch to be toggled
;--------------------------------------------------
waitforequals
     jsr get_switch
     sub.b #11, d0
     bne waitforequals
     rts
;--------------------------------------------------
; it stores the first number gathered to a variable
; in tempx
;--------------------------------------------------
getfirstnumber
    jsr bcd2bin
    move.l x, tempx
    rts
;--------------------------------------------------
; it puts the second number gathered to a variable
; in not realy
;--------------------------------------------------
getsecondnumber
    jsr bcd2bin
    move.l x, tempy
    rts
;-------------------------------------------------
; clears the Hex displays
;-------------------------------------------------
clear_display
    clr.b HEXA
    clr.b HEXB
    clr.b HEXC
    clr.b HEXD
    rts
;-------------------------------------------------
; clears the operation indicators
;-------------------------------------------------
clear_indicators
    clr.l addIndi
    clr.l subIndi
    clr.l mulIndi
    clr.l divIndi
    rts
myprogram
          ;---------------------------------------
          ; Displays the student number
          ;---------------------------------------
           move.b #$27, HEXA
           move.b #$51, HEXB
           move.b #$24, HEXC
           move.b #$33, HEXD
           jsr wait1sec
           jsr wait1sec
;-------------------------------------------------
; calculator starts here
;-------------------------------------------------
calculator
           jsr clear_display ; clears the display
           jsr inputnumbers  ; reads the switches
start
           jsr getfirstnumber ; stores the 1st number
           jsr clear_indicators ; clears the indicators
           jsr waitforoperation ; checks which operation is pressed
           jsr clear_display ; clears the display again
           jsr inputnumbers ; reads the switches again
           jsr getsecondnumber ; stores the 2nd number
           jsr waitforequals ; waits for the equals
PerformOperation
           move.l tempx, x ; copies what was stored in the variables to x
           move.l tempy, y ; copies what was stored in the variable to y
           jsr checkoperation ; remembers what operation was picked and does it
           jsr bin2bcd
           jsr display_bcd ; displays the number
           jmp start
