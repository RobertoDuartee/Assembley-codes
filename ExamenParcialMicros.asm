.ORG 0
.INCLUDE "m16def.inc"

LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16

;LINEA DE PUERTO D CONDICION A
SBI DDRD,0

;LED DE HUMEDAD CONDICION B
SBI DDRD,1

;BUZZER, CONDICION C
SBI DDRD,2

;puntero para flash
LDI ZH,HIGH(0x400<<1)
LDI ZL,LOW(0x400<<1)
LPM R20,Z


MONITOREO:
;BYTE 1
IN R16,PORTA
CPI R16,0x33
BREQ LECTURA
RJMP MONITOREO

;NIVEL DE TEMPERARTURA
LECTURA:
CALL delay1000ms
CALL delay300ms
IN R17,PINA
STS 0x300,R17

;% HUMEDAD RELATIVA
CALL delay1000ms
CALL delay300ms
IN R18,PINA
STS 0x301,R18

;INCUBADORA ABIERTA O CERRADA
CALL delay1000ms
CALL delay300ms
IN R19,PINA
STS 0x302,R19

;COMPARACION ENTRE NIVEL DE TEMPERATURA Y DATO ALMACENADO EN FLASH
COMP_TEMP:
LDS R17,0x300
CP R17,R20
BRSH CONDICIONA

;COMPARACION DE PORCENTAJE DE HUMEDAD RELATIVA
COMP_HUMEDAD:
LDS R18,0x301
CPI R18,20
BRLO CONDICIONB
;SIGUIENTE LECTURA DE HUMEDAD EN CASO DE SER MAYOR AL 20%
CBI PORTD,1

;PUERTA
PUERTA:
LDS R19,0x302
CPI R19,0
BRNE CONDICIONC
RJMP MONITOREO

CONDICIONA:
CBI PORTD,0
CALL delay500ms
SBI PORTD,0
RJMP COMP_HUMEDAD

CONDICIONB:
SBI PORTD,1
RJMP PUERTA

CONDICIONC:
SBI PORTD,2
CALL delay1000ms
CALL delay1000ms
CALL delay1000ms
RJMP MONITOREO



DELAY:
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

delay100ms:
	LDI R28,10
	ciclo3:
		CALL delay10ms
		DEC R28
		BRNE ciclo3
	RET

;delay de 1000 ms
delay1000ms:
	LDI R28,100
	ciclo4:
		CALL delay10ms
		DEC R28
		BRNE ciclo3
	RET

;delay de 300 ms
delay300ms:
	LDI R28,30
	ciclo5:
		CALL delay10ms
		DEC R28
		BRNE ciclo3
	RET

;delay de 500 ms
delay500ms:
	LDI R28,50
	ciclo6:
		CALL delay10ms
		DEC R28
		BRNE ciclo3
	RET

