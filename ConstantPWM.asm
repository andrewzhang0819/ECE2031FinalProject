;PWM signal

ORG &H00

Main:

LOADI	0
STORE	cycle	; cycle = 0

PWM:
LOAD	cycle
SUB		period
JPOS	Main

LOAD	cycle
SUB		duty_cycle
JPOS	Else
Then:
LOADI	3
OUT		LEDs
JUMP	Skip
Else:
LOADI	2
OUT		LEDs
Skip:

LOADI	1		; cycle++
ADD		cycle
STORE	cycle

JUMP	PWM

JUMP 	Main

duty_cycle:		DW	2500
period:			DW	10000
cycle:			DW	0

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