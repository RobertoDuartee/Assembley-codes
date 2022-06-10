.INCLUDE "m16def.inc"
.ORG 0
RJMP MAIN
.ORG 2
RJMP BOTON
.ORG 4
RJMP TECLA
.ORG 0x26
RJMP RFSH

MAIN:

LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16

;INTERRUPROR ON/OF INT0
CBI DDRD,2

;TECLA DE PROGRAMACION 
CBI DDRD,3

;MODOS a Y b 
CBI DDRD,0
CBI DDRD,1

;DISPLAYS
SER R16
OUT DDRA,R16

;PALABRAS DE CONTROL
LDI R16,0b110000000
OUT GICR,R16
LDI R16,0b00001010
OUT MCUCR,R16
LDI R16,0b00000010
OUT TIMSK,R16

SEI


;PUNTERO RAM
LDI XL,LOW(0x60)
LDI XH,HIGH(0x60)
LDI R22,2
LDI R23,0b11111110

;DISPLAY RAM
LDI R16,0b10000000
STS 0x60,R16
STS 0x61,R16


FIN: RJMP FIN

BOTON:
LDI R16,SREG
PUSH R16


SBIC PORTD,0
CALL modoa

SBIC PORTD,1
CALL modob



SALIR:
POP R16
OUT SREG,R16
RETI

modoa:
;LEER FLASH Y GUARDARLA EN RAM DE DISPLAY
LDI ZH,HIGH(DATOS<<1)
LDI ZL,LOW(DATOS<<1)
LPM R16,Z
STS 0x60,R16
RJMP SALIR

modob:
LDI ZH,HIGH(DATOS<<1)
LDI ZL,LOW(DATOS<<1)
LDI R17,2
polling:
LPM R16,Z+
STS 0x60,R16
DEC R17
BRNE polling
RJMP SALIR


RFSH:
;RUTINA DE REFRESH

RETI

TECLA:

CLR R17
;CONTADOR
LDS R16,0x61
INC R16
STS 0x61,R16
CPI R16,5
BRNE SALIR2
STS 0x61,R17

SALIR2:

RETI


PWM:
;modo 14, prescaler 1024
LDI R16, 0b10100010
OUT TCCR1A, R16
LDI R16, 0b00001101
OUT TCCR1B, R16
RET

DATOS:
.ORG 0x400
.DB 0b00000110,0b10110011,0b10010111,0b11000110,0b11110111,0b11111100