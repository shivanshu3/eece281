; mathtest.asm:  Examples using math16.asm routines

$MODDE2
org 0000H
   ljmp MyProgram

dseg at 30h
x:    ds 2
y:    ds 2
bcd:  ds 3

bseg
mf:   dbit 1


$include(math16.asm)

CSEG

; Look-up table for 7-seg displays. 
T_7seg:
    DB 40H, 79H, 24H, 30H, 19H
    DB 12H, 02H, 78H, 00H, 10H

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

wait_for_key1:
key1_is_one:
	jb KEY.1, key1_is_one ; loop while the button is not pressed
key1_is_zero:
	jnb KEY.1, key1_is_zero ; loop while the button is pressed
	ret

; A handy macro to perform an operation and display the result.
domath mac
	Load_x(%0)
	Load_y(%1)
	lcall %2
	lcall hex2bcd
	lcall Display_BCD
	lcall wait_for_key1
endmac


MyProgram:
	mov sp, #07FH ; Initialize the stack pointer
	; For the health of your eyes, turn off all LEDs!
	clr a
	mov LEDG,  a
	mov LEDRA, a
	mov LEDRB, a
	mov LEDRC, a

Forever:
	; Try multiplying 1234 x 10 = 12340
	mov x+0, #low(1234)
	mov x+1, #high(1234)
	mov y+0, #low(10)
	mov y+1, #high(10)
	; mul16 and hex2bcd are in math16.asm
	lcall mul16
	lcall hex2bcd
	; display the result
	lcall Display_BCD
	; Now wait for key1 to be pressed and released so we can see the result.
	lcall wait_for_key1
	
	; There is a macro defined in math16.asm that can be used to load constants
	; to variables x and y. The same code above may be written as:
	Load_x(1234)
	Load_y(20)
	lcall mul16
	lcall hex2bcd
	lcall Display_BCD
	lcall wait_for_key1

	; The 'domath' macro defined above makes the code even easier to read.
	; It includes load_x, load_y, operation, Display_BCD, and wait_for_key1:
	
	;  44444/11 = 4040
	domath(44444, 11, div16)
	;  1000/10 = 100
	domath(1000, 10, div16)
	
	; x/0=65535 (the largest 16-bit number)
	domath(44444, 0, div16)
	
	; 55555/55555=1
	domath(55555, 55555, div16)

	; 1234+4567=5801
	domath(1234, 4567, add16)

	; 4567-1234=3333
	domath(4567, 1234, sub16)

	; sqrt(20736)=144
	domath(20736, 0, sqrt16)
	
	Load_x(255)
	Load_y(255)
	lcall mul16
	lcall sqrt16 ; should display 255
	lcall hex2bcd
	lcall Display_BCD
	lcall wait_for_key1
	
	ljmp Forever
	
END
