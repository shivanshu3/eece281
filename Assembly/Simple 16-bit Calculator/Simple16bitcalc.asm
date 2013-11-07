$modde2
	org 0000H
	ljmp mycode
	$include(math16.asm)  ;Includes the math16.asm file
	
DSEG at 30H       ; Absoulte DATA segments at fixed memory locations
	x:    ds 2    ; Reserves 2 bytes (16 bits) for x
	y:    ds 2    ; Reserves 2 bytes (16 bits) for y
	bcd:	ds 3  ; Reserves 3 bytes for BCD
	type:	ds 1  ; Reserves 1 byte (8 bits) for type

BSEG              ; Absoulte BIT segments at fixed memory locations
	mf:   dbit 1  ; Reserves bit within BIT segment
	
CSEG              ; Absoulte CODE segments at fixed memory locations
	myLUT:        ; Look-up table for 7-seg displays
    DB 0C0H, 0F9H, 0A4H, 0B0H, 099H        ; 0 TO 4
    DB 092H, 082H, 0F8H, 080H, 090H        ; 4 TO 9
    DB 088H, 083H, 0C6H, 0A1H, 086H, 08EH  ; A to F
	T_7seg:       ; Look-up table for 7-seg displays. 
    DB 40H, 79H, 24H, 30H, 19H
    DB 12H, 02H, 78H, 00H, 10H

; An unsigned 16-bit number results in a 5-digit BCD number.
; Use HEX0 to HEX4 to display it
Display:
	MOV 97H, #7FH ;Turns HEX off after Student Number
	MOV 96H, #7FH
	MOV 8FH, #7FH
	
	mov dptr, #myLUT   ;Moves values from LUT to dptr
	; Display Digit 0
    mov A, bcd+0       ;Takes the first two BCD digits
    anl a, #0fh        ;ANDs with 1111B (15D)
    movc A, @A+dptr    ;Picks the n-th byte of LUT, moves to acc
    mov HEX0, A        ;Displays a digit on the HEX Display
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
	clr c          ;Clears carry
	mov a, bcd+0
	rlc a          ;Shifts the bits of acc to the left, leftmost loaded to carry
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
	
StudentNumber:     ;NOTE: Does not turn off HEX 5-7, Display does
	MOV 97H, #30H  ;Displays "3"
	MOV 96H, #40H  ;Displays "0"
	MOV 8FH, #12H  ;Displays "5"
	MOV 8EH, #12H  ;Displays "5"
	MOV 94H, #40H  ;Displays "0"
	MOV 93H, #79H  ;Displays "1"
	MOV 92H, #24H  ;Displays "2"
	MOV 91H, #30H  ;Displays "3"
	MOV R3, #40
L4:	LCALL Wait50ms ;Waits 2 seconds
	DJNZ R3,L4
	RET
key1_is_zero:               ; Prevents x being set to zero while button is held down
	jnb KEY.1, key1_is_zero ; Loop while the button is pressed
	ret	
key2_is_zero:               ; Prevents x being set to zero while button is held down
	jnb KEY.2, key2_is_zero ; Loop while the button is pressed
	ret
key3_is_zero:               ; Prevents x being set to zero while button is held down
	jnb KEY.3, key3_is_zero ; Loop while the button is pressed
	ret
m_switch_is_one:            ; Prevents x being set to zero while switch is up
	mov a, SWC
	anl a, #10B             ; Loop while switch is up
	jnz m_switch_is_one
	ret
d_switch_is_one:            ; Prevents x being set to zero while switch is up
	mov a, SWC
	anl a, #01B             ; Loop while switch is up
	jnz d_switch_is_one
	ret
Operations:
	jnb KEY.3, Addition		; Waits for Key3 before jump
	jnb KEY.2, Subtraction  ; Waits for Key2 before jump
	jnb KEY.1, Equals       ; Waits for Key1 before jump
	
	mov a, SWC
	anl a, #10B             ; Takes the AND to determine if Switch 17 is on
	jnz Multiplication      ; Jumps if the acc is not zero
	mov a, SWC
	anl a, #01B             ; Takes the AND to determine if Switch 16 is on
	jnz Division            ; Jumps if the acc is not zero
	ret
Store:
	lcall bcd2hex           ; Numerand1 in x
	lcall copy_xy           ; Numerand1 in y
	lcall ClearDisplay
	lcall Display
	ret
Equals:
	lcall key1_is_zero   ; Waits for Key1 to be pressed
	mov a,#1H            ; If type is 1H, the AND jumps to AdditionOP
	ANL a, type          ; AND compares bit by bit
	jnz AdditionOP
	mov a,#2H            ; If type is 2H, the AND jumps to SubtractionOP
	ANL a, type
	jnz SubtractionOP
	mov a,#4H            ; If type is 4H, the AND jumps to MultiplicationOP
	ANL a, type          
	jnz MultiplicationOP
	mov a,#8H            ; If type is 8H, the AND jumps to DivisionOP
	ANL a, type
	jnz DivisionOP
	ret
Addition:
	lcall Store          ; Stores the next digit in y
	lcall key3_is_zero
	mov type, #1H        ; Sets type to 1H for "+" identification
	ret
Subtraction:
	lcall Store
	lcall key2_is_zero
	mov type, #2H        ; Sets type to 2H for "-" identification
	ret
Multiplication:
	lcall Store
	lcall m_switch_is_one
	mov type, #4H        ; Sets type to 4H for "x" identification
	ret
Division:
	lcall Store
	lcall d_switch_is_one
	mov type, #8H        ; Sets type to 8H for "/" identification
	ret
AdditionOP:
	lcall bcd2hex ; numerand2 a in x
	lcall xchg_xy ; exchange x and y
	lcall add16
	lcall hex2bcd ; convert 16 bit answer
	lcall display
	ret
SubtractionOP:
	lcall bcd2hex ; numerand2 a in x
	lcall xchg_xy ; exchange x and y
	lcall sub16
	lcall hex2bcd ; convert 16 bit answer
	lcall display
	ret
MultiplicationOP:
	lcall bcd2hex ; numerand2 a in x
	lcall xchg_xy ; exchange x and y
	lcall mul16
	lcall hex2bcd ; convert 16 bit answer
	lcall display
	ret
DivisionOP:
	lcall bcd2hex ; numerand2 a in x
	lcall xchg_xy ; exchange x and y
	lcall div16
	lcall hex2bcd ; convert 16 bit answer
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
	mov SP, #7FH    ;Initializes the Stack pointer, set high
	clr a
	mov LEDRA, a    ;Next 4 lines turn off LEDs
	mov LEDRB, a
	mov LEDRC, a
	mov LEDG, a
	mov bcd+0, a
	mov bcd+1, a
	mov bcd+2, a
	lcall StudentNumber
	lcall Display

forever:
	lcall Operations ;Check if user is done inputting a number
	lcall ReadNumber
	jnc forever
	lcall Shift_Digits
	lcall Display
	ljmp forever
end