$modde2
	
	CSEG at 0
	ljmp mycode

	DSEG at 30H
		bcd: ds 4
		x:	ds 3
		y: ds 3
	BSEG
		mf: dbit 1
        CSEG                                        ; Absolute CODE segements at fixed memory locations
        myLUT:                                        ; Look-up table for 7-seg displays
        DB 0C0H, 0F9H, 0A4H, 0B0H, 099H                ; 0 TO 4
        DB 092H, 082H, 0F8H, 080H, 090H                ; 4 TO 9 
CSEG
Wait1s:
mov R6, #0
mov R2, #180

L3: mov R1, #250

L2: mov R0, #250

L1: djnz R0, L1 ; 3 machine cycles-> 3*30ns*250=22.5us

djnz R1, L2 ; 22.5us*250=5.625ms
jnb TF0, continue
inc R6
clr TF0
lcall InitTimer0
clr TR0
mov TL0,#0
mov TH0,#0
setb TR0
continue:
djnz R2, L3 ; 5.625ms*180=1s (approximately)

ret

;Initializes timer/counter 0 as a 16-bit counter

InitTimer0:

clr TR0 ; Stop timer 0

mov a, #11110000B ; Clear the bits of timer 0

anl a,TMOD

orl a, #00000101B ; Set timer 0 as 16-bit counter

mov TMOD, a

ret

hex2bcd:
        push acc
        push psw
        push AR0
        
        clr a
        mov bcd+0, a ; Initialize BCD to 00-00-00 
        mov bcd+1, a
        mov bcd+2, a
        mov bcd+3, a
        mov r0, #24  ; Loop counter.

hex2bcd_L0:
        ; Shift binary left        
        mov a, x+1
        mov c, acc.7 ; This way x remains unchanged!
        mov a, x+0
        rlc a
        mov x+0, a
        mov a, x+1
        rlc a
        mov x+1, a
        mov a, x+2
        rlc a
        mov x+2, a
        
    
        ; Perform bcd + bcd + carry using BCD arithmetic
        mov a, bcd+0
        addc a, bcd+0
        da a
        mov bcd+0, a
        mov a, bcd+1
        addc a, bcd+1
        da a
        mov bcd+1, a
        mov a, bcd+2
        addc a, bcd+2
        da a
        mov bcd+2, a
        mov a, bcd+3
        addc a, bcd+3
        da a
        mov bcd+3, a
      

        djnz r0, hex2bcd_L0

        pop AR0
        pop psw
        pop acc
        ret
	
Display:
        mov dptr, #myLUT
        ; Display Digit 0
        mov A, bcd+0
        anl a, #0fh
        movc A, @A+dptr
        mov HEX0, A
        ; Display Digit 1
        mov A, bcd+0
        swap a
        anl a, #0fh
        movc A, @A+dptr
        mov HEX1, A
        ; Display Digit 2
        mov A, bcd+1
        anl a, #0fh
        movc A, @A+dptr
        mov HEX2, A
        ; Display Digit 3
        mov A, bcd+1
        swap a
        anl a, #0fh
        movc A, @A+dptr
        mov HEX3, A
        ; Display Digit 4
        mov A, bcd+2
        anl a, #0fh
        movc A, @A+dptr
        mov HEX4, A
        ; Display Digit 5
        mov A, bcd+2
        swap a
        anl a, #0fh
        movc A, @A+dptr
        mov HEX5, A
        ; Display Digit 6
        mov A, bcd+3
        anl a, #0fh
        movc A, @A+dptr
        mov HEX6, A
        ; Display Digit 7
        mov A, bcd+3
        swap a
        anl a, #0fh
        movc A, @A+dptr
        mov HEX7, A
        ret

add24:
	push acc
	push psw
	mov a,x+0
	add a,y+0
	mov x+0,a
	mov a,x+1
	addc a,y+1
	mov x+1,a
	mov a,x+2
	addc a,y+2
	mov x+2,a
	pop psw
	pop acc
	ret

fixOverflow:
	mov a, r6
	jz return
	mov x+0, #0FFH
	mov x+1, #0FFH
	mov x+2, #00H
	mulL1: 
	mov y+0, #0FFH
	mov y+1, #0FFH
	mov y+2, #00H
	lcall add24
	djnz R6, mulL1
	mov y+1, TH0
	mov y+0, TL0
	lcall add24
	return: ret

mycode:
	mov SP, #7FH
	mov LEDRA,#0
	mov LEDRB,#0
	mov LEDRC,#0
	mov LEDG,#0
	
	;mov x+0,#0FFH
	;mov x+1,#0FFH
	;mov x+2,#0H
	;mov y+0,#0FFH
	;mov y+1,#0FFH
	;mov y+2,#0H
	
	;call add24
	;mov LEDRC,x+2
	;mov LEDRB,x+1
	;mov LEDRA,x+0
	
	;jmp forever
	
	
	; Configure T0 as an input (original 8051 only).

; Not needed but harmless in the DE2-8052
setb T0

; 1) Set up the counter to count pulses from T0

lcall InitTimer0

; Stop counter 0

clr TR0

; 2) Reset the counter

mov TL0, #0

mov TH0, #0

; 3) Start counting

setb TR0

; 4) Wait one second

lcall Wait1s

; 5) Stop counter 0, TH0-TL0 has the frequency!

clr TR0

; Do something useful with the frequency

call fixOverflow
lcall hex2bcd
lcall display
lcall hex2bcd
lcall display
mov LEDG, x+0
mov LEDRA, x+1
mov LEDRB, x+2

forever:
	
	jmp forever




	
end