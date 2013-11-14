$modde2
org 0000H

	CSEG at 0
	ljmp mycode

	DSEG at 30H
bcd:	ds 3
x:    	ds 2
y:    	ds 2

bseg
mf:   dbit 1

$include(math16.asm)

	CSEG

; Look-up table for 7-seg displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 5 TO 9
    DB 088H, 083H, 0C6H, 0A1H, 086H, 08EH  ; A to F

	CSEG

; Look-up table for 7-seg displays. 
T_7seg:
    DB 40H, 79H, 24H, 30H, 19H
    DB 12H, 02H, 78H, 00H, 10H

wait_for_key1:
	key1_is_one:
	jb KEY.1, key1_is_one ; loop while the button is not pressed
	key1_is_zero:
	jnb KEY.1, key1_is_zero ; loop while the button is pressed
	ret


domath mac
	Load_x(%0)
	Load_y(%1)
	lcall %2
	lcall hex2bcd
	lcall Display_BCD
	lcall wait_for_key1
endmac

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
    ret

Shift_Digits:
	mov R0, #4 ; shift left four bits
Shift_Digits_L0:
	clr c
	mov a, bcd+0
	rlc a
	mov bcd+0, a
	mov a, bcd+1
	rlc a
	mov bcd+1, a
	mov a, bcd+2
	rlc a
	mov bcd+2, a
	djnz R0, Shift_Digits_L0
	; R7 has the new bcd digit	
	mov a, R7
	orl a, bcd+0
	mov bcd+0, a
	; make the four most significant bits of bcd+2 zero
	mov a, bcd+2
	anl a, #0fH
	mov bcd+2, a
	ret

Wait50ms:
;33.33MHz, 1 clk per cycle: 0.03us
	mov R0, #30
L3: mov R1, #74
L2: mov R2, #250
L1: djnz R2, L1 ;3*250*0.03us=22.5us
    djnz R1, L2 ;74*22.5us=1.665ms
    djnz R0, L3 ;1.665ms*30=50ms
    ret

; Check if SW0 to SW15 are toggled up.  Returns the toggled switch in
; R7.  If the carry is not set, no toggling switches were detected.
ReadNumber:
	mov r4, SWA ; Read switches 0 to 7
	mov r5, SWB ; Read switches 8 to 15
	mov a, r4
	orl a, r5
	jz ReadNumber_no_number
	lcall Wait50ms ; debounce
	mov a, SWA
	clr c
	subb a, r4
	jnz ReadNumber_no_number ; it was a bounce
	mov a, SWB
	clr c
	subb a, r5
	jnz ReadNumber_no_number ; it was a bounce
	mov r7, #16 ; Loop counter
ReadNumber_L0:
	clr c
	mov a, r4
	rlc a
	mov r4, a
	mov a, r5
	rlc a
	mov r5, a
	jc ReadNumber_decode
	djnz r7, ReadNumber_L0
	sjmp ReadNumber_no_number	
ReadNumber_decode:
	dec r7
	setb c
ReadNumber_L1:
	mov a, SWA
	jnz ReadNumber_L1
ReadNumber_L2:
	mov a, SWB
	jnz ReadNumber_L2
	ret
ReadNumber_no_number:
	clr c
	ret
	
DisplayStudentNumber:
    mov HEX7, #0B0H
    mov HEX6, #0B0H
    mov HEX5, #0A4H
    mov HEX4, #099H
    mov HEX3, #092H
    mov HEX2, #0F9H
    mov HEX1, #0A4H
    mov HEX0, #0F8H
    ret

; An unsigned 16-bit number results in a 5-digit BCD number.
; Use HEX0 to HEX4 to display it
Display_BCD:
	
	mov dptr, #T_7seg

	mov a, bcd+2
	anl a, #0FH
	movc a, @a+dptr
	mov HEX4, a
	
	mov a, bcd+1
	swap a
	anl a, #0FH
	movc a, @a+dptr
	mov HEX3, a
	
	mov a, bcd+1
	anl a, #0FH
	movc a, @a+dptr
	mov HEX2, a

	mov a, bcd+0
	swap a
	anl a, #0FH
	movc a, @a+dptr
	mov HEX1, a
	
	mov a, bcd+0
	anl a, #0FH
	movc a, @a+dptr
	mov HEX0, a
	
	ret


mycode:
	mov SP, #7FH
	
	;Display student number below:
	call DisplayStudentNumber
	mov R6,#40
	wait2sec: call Wait50ms
	djnz R6,wait2sec
	mov R6,#0
	mov HEX7,#7FH
	mov HEX6,#7FH
	mov HEX5,#7FH
	;Resume to main program:
	
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov LEDRC, a
	mov LEDG, a
	mov bcd+0, a
	mov bcd+1, a
	mov bcd+2, a
	lcall Display

forever:
	lcall ReadNumber
	jnc forever
	lcall Shift_Digits
	lcall Display
	mov LEDRA,#07FH
	ljmp forever
	
newforever:
	jmp newforever	
end
