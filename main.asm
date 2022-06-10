;
; Examen práctico P1.asm
;
; Created: 22/09/2020 01:44:51 p. m.
; Author : Roberto
;


//Instrucciones del compilador
.org 0
.include "m16def.inc"

//Puntero a la pila
LDI R16, HIGH(RAMEND)
OUT SPH, R16
LDI R16, LOW(RAMEND)
OUT SPL, R16

//Nombres de registros
.def SensorA=R17
.def SensorB=R18
.def SensorC=R19
.def CompA1=R20
.def CompA2=R21
.def CompB1=R22
.def CompB2=R23
.def CompC1=R24
.def CompC2=R25

//Puertos de salida
SBI DDRD, 1
SBI DDRD, 2
SBI DDRD, 3
SBI DDRD, 4

//Puntero a flash y carga a registros
LDI ZH, HIGH(0x400<<1)
LDI ZL, LOW(0x400<<1)
LPM CompA1, Z+
LPM CompA2, Z+
LPM CompB1, Z+
LPM CompB2, Z+
LPM CompC1, Z+
LPM CompC2, Z

//Inicio
switch:
	SBIC PINB, 0
	RJMP switch

IN SensorA, PINA
IN SensorB, PINB
IN SensorC, PINC
CLR R15

//Sensor central
CP CompB1, SensorB
CPC CompB2, R15
BRSH detener

//Sensor izquierdo
CLC
CP CompA1, SensorA
CPC CompA2, R15
BRSH giroder

//Sensor derecho
CLC
CP CompC1, SensorC
CPC CompC2, R15
BRSH giroizq

//Avanzar
SBI PORTD, 1
SBI PORTD, 3
CBI PORTD, 2
CBI PORTD, 4
CALL delay100ms
RJMP switch

//Movimientos
detener:
	SBI PORTD, 2
	SBI PORTD, 4
	CBI PORTD, 1
	CBI PORTD, 3
	CALL delay100ms
	RJMP switch

giroder:
	SBI PORTD, 1
	CBI PORTD, 2
	CBI PORTD, 3
	CBI PORTD, 4
	CALL delay100ms
	RJMP switch

giroizq:
	SBI PORTD, 3
	CBI PORTD, 1
	CBI PORTD, 2
	CBI PORTD, 4
	CALL delay100ms
	RJMP switch

//Retardos
delay10ms:
	LDI R26, 104
	ciclo2:
		LDI R27, 255
		ciclo1:
			DEC R27
			BRNE ciclo1
		DEC R26
		BRNE ciclo2
	RET

delay100ms:
	LDI R28, 10
	ciclo3:
		CALL delay10ms
		DEC R28
		BRNE ciclo3
	RET