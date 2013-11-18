$MODDE2

CSEG
org 0000H
   ljmp MyProgram

; On the DE2-8052, with a 33.33MHz clock, one cycle takes 30ns
Wait1s:
	mov R2, #180
	L3: mov R1, #250
	L2: mov R0, #250
	L1: djnz R0, L1 ; 3 machine cycles-> 3*30ns*250=22.5us
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
	mov LEDRB,TH0
	mov LEDRA,TL0

forever:
    jmp forever

END
