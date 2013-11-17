$modde2

CSEG

mycode:
	mov SP, #7FH
	clr a
	mov LEDRA, a
	mov LEDRB, a
	mov LEDRC, a
	mov LEDG, a
	
	
forever:
	mov a, T0
	mov LEDRA, a
	ljmp forever
	
END