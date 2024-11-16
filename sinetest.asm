;PWM signal

ORG &H00

LOADI	0
OUT		extmemaddr

Loop:
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

iteration:	DW	0
count:		DW	10000

; constants
; IO addresses
switches:  		EQU &h0000
LEDs:      		EQU &h0001
timer:     		EQU &h0002
hex0:      		EQU &h0004
hex1:      		EQU &h0005
extmemdata:		EQU	&h0070
extmemaddr:		EQU &h0071
extmembank:		EQU &h0072
extmemprot:     EQU &h0074