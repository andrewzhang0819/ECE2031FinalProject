; Blank.asm
; There's nothing here yet...

ORG &H00
LOADI	0			; go to bank 0
OUT		extmembank

LOADI	&h10		; go to address x10 in bank 0
OUT		extmemaddr

LOADI	69			; store 69 in external memory
OUT		extmemdata

LOADI	0			; check that it works
IN		extmemdata
STORE	result

END:
JUMP	END

ORG &H25
result:		DW 0

; constants
; IO addresses
switches:  		EQU &h0000
LEDs:      		EQU &h0010
timer:     		EQU &h0020
hex0:      		EQU &h0040
hex1:      		EQU &h0050
extmemdata:		EQU	&h0070
extmemaddr:		EQU &h0071
extmembank:		EQU &h0072