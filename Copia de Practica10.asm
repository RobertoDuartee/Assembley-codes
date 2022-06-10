.INCLUDE "m16def.inc"
.ORG 0
RJMP MAIN
.ORG 2
RJMP BOTONI
.ORG 4
RJMP BOTOND
.ORG 6
RJMP CONTEO
.ORG 0x26
RJMP RFSH

MAIN:

;Displays
SER R16
OUT DDRC,R16

;switches
CBI DDRB,0
CBI DDRB,1

;BOTON UP INT0+
CBI DDRD,2

;BOTON DOWN INT1
CBI DDRD,3

;PALABRAS DE CONTROL

LDI R16,0b00000010
OUT TIMSK,R16

SEI 
LDI R16,38
OUT OCR0,R16
LDI R16,0b00001101
OUT TCCR0,R16

;RAM DE DISPLAY
LDI XH,HIGH(0x60)
LDI XL,LOW(0x60)
LDI R24,4
LDI R25,0b11101111

CLR R16
STS 0x60,R16
STS 0x61,R16
STS 0x62,R16
STS 0x63,R16

LDI R16,77
OUT OCR2,R16


AGAIN:
SBIC PORTB,0
RJMP SW0

SBIC PORTB,1
RJMP SW1

RJMP AGAIN

SW0:

;APAGAR INTERRUPCIONES EXTERNAS
LDI R16,0b00000000
OUT GICR,R16



LDI R16,0b00001111
OUT TCCR2,R16
RJMP AGAIN


SW1:

;APAGAR TIMER 2 DE SW0
LDI R16,77
OUT OCR2,R16
LDI R16,0b00001111
OUT TCCR2,R16


;PALABRAS DE CONTROL INT0/INT1
LDI R16,0b11000000
OUT GICR,R16
LDI R16,0b00001010
OUT MCUCR,R16

RJMP AGAIN


RFSH:
IN R16,SREG
PUSH R16

LD R0,X+
MOV R20,R25
ANDI R20,0xF0
ADD R0,R20
OUT PORTC,R0
ROL R25
DEC R24
BRNE SALIR
LDI XH,HIGH(0x60)
LDI XL,LOW(0x60)
LDI R24,4
LDI R25,0b11101111

SALIR:
POP R16
OUT SREG,R16
RETI

BOTONI:
IN R16,SREG
PUSH R16

CALL INCREMENTAR

POP R16
OUT SREG,R16
RETI

BOTOND:
IN R16,SREG
PUSH R16

CALL DECREMENTAR

POP R16
OUT SREG,R16
RETI

CONTEO:
IN R16,SREG
PUSH R16

CALL INCREMENTAR
SBI PORTA,0
CBI PORTA,0

POP R16
OUT SREG,R16
RETI

INCREMENTAR:
CLR R17
LDS R16,0x63
INC R16
STS 0x63,R16
CPI R16,10
BRNE SALIR
STS 0x63,R17

LDS R16,0x62
INC R16
STS 0x62,R16
CPI R16,10
BRNE SALIR
STS 0x62,R17

LDS R16,0x61
INC R16
STS 0x61,R16
CPI R16,10
BRNE SALIR
STS 0x61,R17

LDS R16,0x60
INC R16
STS 0x60,R16
CPI R16,10
BRNE SALIR
STS 0x60,R17

SALIR:
RET

DECREMENTAR:
LDI R17,9
LDS R16,0x63
DEC R16
STS 0x63,R16
CPI R16,0xFF
BRNE SALIR
STS 0x63,R17

LDS R16,0x63
DEC R16
STS 0x63,R16
CPI R16,0xFF
BRNE SALIR
STS 0x63,R17

LDS R16,0x63
DEC R16
STS 0x63,R16
CPI R16,0xFF
BRNE SALIR
STS 0x63,R17

LDS R16,0x63
DEC R16
STS 0x63,R16
CPI R16,0xFF
BRNE SALIR
STS 0x63,R17

SALIR:

RET


/*
delay10ms:
	LDI R26,104;
	ciclo2:
		LDI R27,255
		ciclo1:
			DEC R27
			BRNE ciclo1
		DEC R26
	    BRNE ciclo2

RET
*/