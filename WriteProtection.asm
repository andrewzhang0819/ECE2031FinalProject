; WriteProtection.asm
; There's nothing here yet...

ORG &H00
; set bank 0 to read only and then back
LOADI	0			; set to bank 0
OUT		extmembank
LOADI   1			; set write protection to bank 0
OUT     extmemprot

LOADI	0			; set bank 0 back 
OUT		extmemprot

; set all banks to read only
LOADI	0			; set to bank 0 
OUT		extmembank	
LOADI	1     		; set write protection to bank 0
OUT     extmemprot

OUT     extmembank 	; set to bank 1
OUT     extmemprot	; set write protection to bank 1

LOADI   2			; set to bank 2
OUT     extmembank
LOADI   1 			; set write protection to bank 2
OUT     extmemprot

LOADI   3			; set to bank 3
OUT     extmembank  
LOADI   1			; set write protection to bank 3
OUT 	extmembank 	

; check if you can actually write to it
LOADI   0       	; set to bank 0 
OUT     extmembank
LOADI   1			; try to write 1 to bank 0
OUT     extmemdata
IN      extmemdata	; should not display 1

LOADI   1       	; set to bank 1
OUT     extmembank
LOADI   2			; try to write 1 to bank 1
OUT     extmemdata
IN      extmemdata	; should not display 2

LOADI   2       	; set to bank 2
OUT     extmembank
LOADI   3			; try to write 1 to bank 2
OUT     extmemdata
IN      extmemdata	; should not display 3

LOADI   3       	; set to bank 3
OUT     extmembank
LOADI   4			; try to write 1 to bank 3
OUT     extmemdata
IN      extmemdata	; should not display 4

; test if turning off write protection will now be able to write
LOADI	0			; go to bank 0
OUT     extmembank  
OUT     extmemprot  ; turn off write protection
LOADI   1           ; try to write 1 to bank 0
OUT     extmemdata
IN  	extmemdata	; should display 1

OUT     extmembank  ; go to bank 1
LOADI   1			
OUT     extmemprot	; turn off write protection
LOADI   2			
OUT     extmemdata 	; should display 2
IN      extmemdata

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
extmembank:     EQU &h0073
extmemprot:     EQU &h0074