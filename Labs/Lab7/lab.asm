$modde2
	
	CSEG at 0
	ljmp mycode

	DSEG at 30H
		bcd:	ds 1
		counter: ds 2
	BSEG
		mf: dbit 1
	$include(mylut.asm)
   
Wait50ms:
;33.33MHz, 1 clk per cycle: 0.03us
	mov R0, #30
L3: mov R1, #74
L2: mov R2, #250
L1: djnz R2, L1 ;3*250*0.03us=22.5us
    djnz R1, L2 ;74*22.5us=1.665ms
    djnz R0, L3 ;1.665ms*30=50ms
    ret

getNum:
	mov R6,SWA
	mov R7,SWB
	mov a,R7
	anl a,#03H
	mov R7,a
	;Note: R6 and R7 will be modified withing "display" routines
	;Permanent storage for display of 3 numbers:
	mov a,R6
	mov R4,a
	mov a,R7
	mov R5,a
	ret
	
displaysign:
	clr c
	mov a,R7
	subb a,#01B
	jnc label1
	jmp displayminus
	
	label1:
	jnz displayplus
	jmp secondconditionplus
	
	secondconditionplus:
	clr c
	mov a,R6
	subb a,#00100101B
	jnc label2
	jmp displayminus
	
	label2:
	jnz displayplus
	jmp displayplus
	
	displayplus:
	mov HEX3,#7FH
	ret
	displayminus:
	mov HEX3,#3FH
	ret

displaynum1:
	mov dptr,#myLUTnum1
	mov a,R6
	jz decrementR7_num1
	loop1_num1:
	dec R6
	inc dptr
	mov a,R6
	jnz loop1_num1
	decrementR7_num1:
	mov a,R7
	jz displayHex_num1
	mov R6,#0FFH
	dec R7
	inc dptr
	mov a,R7
	jnz loop1_num1
	
	mov a,R6
	jnz loop1_num1
	
	displayHex_num1:
	clr a
	movc a,@a+dptr
	mov HEX2,a
	;put the numbers back in position:
	mov a,R4
	mov R6,a
	mov a,R5
	mov R7,a
	ret

displaynum2:
	mov dptr,#myLUTnum2
	mov a,R6
	jz decrementR7_num2
	loop1_num2:
	dec R6
	inc dptr
	mov a,R6
	jnz loop1_num2
	decrementR7_num2:
	mov a,R7
	jz displayHex_num2
	mov R6,#0FFH
	dec R7
	inc dptr
	mov a,R7
	jnz loop1_num2
	
	mov a,R6
	jnz loop1_num2
	
	displayHex_num2:
	clr a
	movc a,@a+dptr
	mov HEX1,a
	;put the numbers back in position:
	mov a,R4
	mov R6,a
	mov a,R5
	mov R7,a
	ret

displaynum3:
	mov dptr,#myLUTnum3
	mov a,R6
	jz decrementR7_num3
	loop1_num3:
	dec R6
	inc dptr
	mov a,R6
	jnz loop1_num3
	decrementR7_num3:
	mov a,R7
	jz displayHex_num3
	mov R6,#0FFH
	dec R7
	inc dptr
	mov a,R7
	jnz loop1_num3
	
	mov a,R6
	jnz loop1_num3
	
	displayHex_num3:
	clr a
	movc a,@a+dptr
	mov HEX0,a
	;put the numbers back in position:
	mov a,R4
	mov R6,a
	mov a,R5
	mov R7,a
	ret

mycode:
	mov SP, #7FH
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov LEDRC, a
	mov LEDG, a
	
forever:
	call getNum;num stored in R7-R6
	call displaysign
	call displaynum1
	call displaynum2
	call displaynum3
	;mov HEX0,#099H
	;mov HEX1,#082H
	;mov HEX2,#083H
	;mov HEX3,#08EH
	jmp  forever
	
end