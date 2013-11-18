$MODDE2

CSEG
org 0000H
   ljmp MyProgram

add24:
	;x=x+y
	mov a,R0
	add a,R3
	mov R0,a
	mov a,R1
	addc a,R4
	mov R1,a
	mov a,R2
	addc a,R5
	mov R2,a
	ret

multiply24:
	;x=65536*R7
	mov R3,#0FFH
	mov R4,#0FFH
	mov R5,#0
	mov R0,#0
	mov R1,#0
	mov R2,#0
	mov a,R7
	mov R6,a
	jnz multiply24_L1
	ret
	multiply24_L1:
	call add24;x=x+65536
	dec R6
	mov a,R6
	jnz multiply24_L1
	ret
	

; On the DE2-8052, with a 33.33MHz clock, one cycle takes 30ns
Wait1s:
	mov R7,#0
	mov R2, #178
	L3: mov R1, #250
	L2: mov R0, #250
	L1: djnz R0, L1 ; 3 machine cycles-> 3*30ns*250=22.5us
	jnb TF0,continue
	;--------------------------------------------------------------------
	;Overflow occured, increment R7, set the registers to 0, start timer:
	clr TF0
	inc R7
	;--------------------------------------------------------------------
	continue:
	djnz R1, L2 ; 22.5us*250=5.625ms
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


MyProgram:
    mov SP, #7FH ; Set the stack pointer to the begining of idata
	mov LEDRA, #0
	mov LEDRB, #0
	mov LEDRC, #0
	mov LEDG, #0
forever:	
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
	; Do something useful with the frequency!
	
	;Display frequency on LED's
	
	;------------------------------------------------------------
	;Display values of counter registers, and the overflow register (R7)
	;mov LEDRB,TH0
	;mov LEDRA,TL0
	;mov LEDG,R7
	;------------------------------------------------------------
	
	call multiply24
	mov R3,TL0
	mov R4,TH0
	mov R5,#0
	call add24
	mov LEDRB,R2
	mov LEDRA,R1
	mov LEDG,R0
	
    jmp forever

END
