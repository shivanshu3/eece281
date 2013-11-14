$modde2

	
	CSEG at 0
	ljmp mycode

	DSEG at 30H
		bcd:	ds 3
		x: ds 2
		y: ds 2
		type: ds 1
	BSEG
		mf: dbit 1
	
	$include(math16.asm)
	CSEG

; Look-up table for 7-seg displays
myLUT:
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9
    DB 088H, 083H, 0C6H, 0A1H, 086H, 08EH  ; A to F

; Look-up table for 7-seg displays. 
T_7seg:
    DB 40H, 79H, 24H, 30H, 19H
    DB 12H, 02H, 78H, 00H, 10H

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
	
studentnumber:
	mov 97H, #30H
	mov 96H, #30H
	mov 8FH, #24H
	mov 8EH, #19H
	mov 94H, #12H
	mov 93H, #79H
	mov 92H, #24H
	mov 91H, #78H
	mov R3,  #40
L4: lcall Wait50ms
	djnz R3, L4
	mov 97H, #7FH
	mov 96H, #7FH
	mov 8FH, #7FH
	mov 8EH, #7FH
	mov 94H, #7FH
	mov 93H, #7FH
	mov 92H, #7FH
	mov 91H, #7FH
	ret
	
Operation:
	jnb KEY.1, Equal
	jnb KEY.3, Addition
	jnb KEY.2, Subtraction
	mov a, SWC
	anl a, #10B
	jnz multiplication
	mov a, SWC
	anl a, #01B
	jnz division
	ret

Store:
	lcall bcd2hex; numerand1 in x
	lcall copy_xy; numerand1 in y
	lcall ClearDisplay
	ret
	
Equal:
	lcall key1_is_zero
	mov a, #00000010H
	anl a, type
	jnz additionOP
	mov a, #00000020H
	anl a, type
	jnz subtractionOP
	mov a, #00000040H
	anl a, type
	jnz multiplication_op
	mov a, #00000080H
	anl a, type
	jnz division_op
	ret
	
Addition:
	lcall store
	lcall key3_is_zero
	mov type, #00000010H
	ret

Subtraction:
	lcall store
	lcall key2_is_zero
	mov type, #00000020H
	ret

Multiplication:
	lcall store
	lcall SW17_is_one
	mov type, #00000040H
	ret

Division:
	lcall store
	lcall SW16_is_one
	mov type, #00000080H
	ret
	
key2_is_zero:
	jnb KEY.2, key2_is_zero
	ret
	
key3_is_zero:
	jnb KEY.3, key3_is_zero ; loop while the button is pressed
	ret
	
key1_is_zero:
	jnb KEY.1, key1_is_zero ; loop while the button is pressed
	ret
	
sw17_is_one:
	mov a, SWC
	anl a, #10B
	jnz sw17_is_one
	ret

sw16_is_one:
	mov a, SWC
	anl a, #01B
	jnz sw16_is_one
	ret
	
AdditionOP:
	lcall bcd2hex
	lcall xchg_xy
	lcall add16
	lcall hex2bcd
	lcall display
	ret

SubtractionOP:
	lcall bcd2hex
	lcall xchg_xy
	lcall sub16
	lcall hex2bcd
	lcall display
	ret

Multiplication_op:
	lcall bcd2hex
	lcall xchg_xy
	lcall mul16
	lcall hex2bcd
	lcall display
	ret
	
Division_op:
	lcall bcd2hex
	lcall xchg_xy
	lcall div16
	lcall hex2bcd
	lcall display
	ret
	
ClearDisplay:
	clr a
	mov bcd+0, a  ;bcd+0 is an 8-bit value, but 2 bcd digits
	mov bcd+1, a
	mov bcd+2, a
	mov HEX0,#40H ;Displays "0"
	mov HEX1,#40H
	mov HEX2,#40H
	mov HEX3,#40H
	mov HEX4,#40H
	ret

mycode:
	mov SP, #7FH
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov LEDRC, a
	mov LEDG, a
	mov bcd+0, a
	mov bcd+1, a
	mov bcd+2, a
	lcall studentnumber
	lcall display
	
forever:
	lcall operation
	lcall ReadNumber	
	jnc   forever
	lcall Shift_Digits
	lcall Display
	ljmp  forever
	
end