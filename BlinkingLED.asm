;Variable PWM signal

ORG &H00

Main:

LOADI	0
OUT		extmemaddr	; reset duty cycle index
STORE	iteration	; reset iteration

SetDutyCycle:
LOAD	iteration	; is iteration below 1000?
SUB		period
JPOS	Main

IN		extmemdata	; set duty cycle
STORE	duty_cycle
OUT		hex0

LOADI	1			; iteration++
ADD		iteration
STORE	iteration

LOADI	0
STORE	cycle		; cycle = 0

PWM:
LOAD	cycle		; is cycle < 1000?
SUB		period
JPOS	SetDutyCycle

LOAD	cycle		; is cycle less than duty cycle?
SUB		duty_cycle
JPOS	Else
Then:
LOADI	1			; yes, keep LEDs on
OUT		LEDs
JUMP	Skip
Else:
LOADI	0			; no, turn LEDs off
OUT		LEDs
Skip:

LOADI	1			; cycle++
ADD		cycle
STORE	cycle

JUMP	PWM

JUMP 	SetDutyCycle

JUMP	Main

duty_cycle:		DW	0
period:			DW	1000
cycle:			DW	0
iteration:		DW	0

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