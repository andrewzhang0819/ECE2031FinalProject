; Final_Demo.asm
; Read from a table of sine values and use pulse width modulation (PWN)
; to simulate a sine value on the LEDs. 

ORG &H00

CheckSwitch:
IN		switches		; Reads the switches

MOD:					; switches % 360 
SUB 	&H168        	; AC = AC - 360
JNEG 	DONE        	; If AC < 0, we're done, AC contains the remainder
JUMP 	MOD        		; Else, repeat the loop

DONE:
ADD 	&H168        	; If AC < 0 in the previous step, restore AC by adding 360 back
STORE 	value     		; Store result (A % 360) in memory in Value

; Not exactly sure after this point?
; I just copy and pasted the sinetest code after this
START:
LOADI	0				; Goes to memory address 0
OUT		extmemaddr		

Loop:					; 
LOAD	iteration
SUB		count
JPOS	End

IN		extmemdata

LOADI	1
ADD		iteration
STORE	iteration
JUMP	Loop

End:
JUMP	End

; necessary constants
duty_cycle:		DW	2500
period:			DW	10000
cycle:			DW	0
iteration:		DW	0
count:			DW	10000 ; shouldnt this only be like 360 or 720 if we do cos as well?

; other constants
mask:     		DW  360
value: 	        DW  0

; IO addresses
switches:  		EQU &h0000
LEDs:      		EQU &h0010
timer:     		EQU &h0020
hex0:      		EQU &h0040
hex1:      		EQU &h0050
extmemdata:		EQU	&h0070
extmemaddr:		EQU &h0071
extmembank:		EQU &h0072
extmemauto:     EQU &h0073
extmemprot:     EQU &h0074