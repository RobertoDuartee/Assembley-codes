;
; Examen práctico P2.asm
;
; Created: 27/10/2020 06:23:35 p. m.
; Author : Roberto
;

//Direcciones RAM: 
//0x60 - lectura nueva A
//0x61 - lectura anterior A
//0x62 - lectura nueva B
//0x63 - lectura anterior B

.include "m16def.inc"
.def contador = R17
.def dutyA = R18
.def dutyB = R19
.def nuevoA = R20
.def nuevoB = R21
.def anteriorA = R22
.def anteriorB = R23

.org 0
	RJMP main
.org 2
	RJMP iniciar
.org 4
	RJMP stop
.org 0x26
	RJMP timer

main:
	//Pila
	LDI R16, HIGH(RAMEND)
	OUT SPH, R16
	LDI R16, LOW(RAMEND)
	OUT SPL, R16
    ;LED DE PRUEBA
    SBI DDRC,0
	//Puertos de salida
	SBI DDRD, 5 //Para señal A
	SBI DDRD, 4 //Para señal B
	//Interrupciones externas
	LDI R16, 0b11000000
	OUT GICR, R16
	LDI R16, 0b00001010
	OUT MCUCR, R16
	//Interrupción Timer 0 Compare
	LDI R16, 0b00000010
	OUT TIMSK, R16
	SEI
	fin:
		RJMP fin

//Interrupción por señal de inicio - encoder
iniciar:
	//Inicia timer
	LDI R16, 77
	OUT OCR0, R16
	LDI R16, 0b00001101
	OUT TCCR0, R16
	LDI contador, 10
	RETI

//Interrupción por timer 10ms
timer:
	//Guardar Entorno
	IN R16, SREG
	PUSH R16
	//Checa si ya pasaron los 100ms
	DEC contador
	BRNE salir	//Regresa a main hasta que pasan 100ms

		LDI contador, 10
		//Lee la señal y la guarda en RAM
		IN nuevoA, PINA
		IN nuevoB, PINB
		LDS anteriorA, 0x60
		STS 0x61, anteriorA
		STS 0x60, nuevoA
		LDS anteriorB, 0x62
		STS 0x63, anteriorB
		STS 0x62, nuevoB
		//Configuración T1 - Modo 14 (Top)
		LDI R16, HIGH(780)
		OUT ICR1H, R16
		LDI R16, LOW(780)
		OUT ICR1L, R16
		//Compara corriente A y B
		CP nuevoA, anteriorA
		BREQ igualA
		ADD nuevoA, anteriorA
		BREQ contrarioA
		LDS anteriorA, 0x61
		LDS nuevoA, 0x60
		CP nuevoA, anteriorA
		BRGE mayorA
		RJMP menorA
		compB:
			CP nuevoB, anteriorB
			BREQ igualB
			ADD nuevoB, anteriorB
            ;----------LINEAS AGREGADAS-----
			BREQ contrarioB1
            contrarioB1: RJMP contrarioB
            ;------------------------------
			LDS anteriorB, 0x63
			LDS nuevoB, 0x62
			CP nuevoB, anteriorB
			BRGE mayorB
			RJMP menorB

	salir:
		//Recupera entorno
		POP R16
		OUT SREG, R16
		RETI

		mayorA:
			//Duty cycle 80% - Match
			LDI R16, HIGH(624)
			MOV R0, R16
			OUT OCR1AH, R16
			LDI R16, LOW(624)
			MOV R1, R16
			OUT OCR1AL, R16
			CALL iniciarT1
			RJMP compB
		menorA:
			//Duty cycle 20% - Match
			LDI R16, HIGH(156)
			MOV R0, R16
			OUT OCR1AH, R16
			LDI R16, LOW(156)
			MOV R1, R16
			OUT OCR1AL, R16
			CALL iniciarT1
			RJMP compB
		contrarioA:
			//Duty cycle 50% - Match
			LDI R16, HIGH(390)
			MOV R0, R16
			OUT OCR1AH, R16
			LDI R16, LOW(390)
			MOV R1, R16
			OUT OCR1AL, R16
			CALL iniciarT1
			RJMP compB
		igualA:
			//Carga el match de duty cycle anterior
			OUT OCR1AH, R0
			OUT OCR1AL, R1
			CALL iniciarT1
			RJMP compB

		mayorB:
			//Duty cycle 80% - Match
			LDI R16, HIGH(624)
			MOV R2, R16
			OUT OCR1BH, R16
			LDI R16, LOW(624)
			MOV R3, R16
			OUT OCR1BL, R16
			CALL iniciarT1
			RJMP salir
		menorB:
			//Duty cycle 20% - Match
			LDI R16, HIGH(156)
			MOV R2, R16
			OUT OCR1BH, R16
			LDI R16, LOW(156)
			MOV R3, R16
			OUT OCR1BL, R16
			CALL iniciarT1
			RJMP salir
		igualB:
			//Carga match de duty cycle anterior
            ;----------LINEAS AGREGADAS-----
            SBI PORTC,0
            CALL delay10ms
            CALL delay10ms
            CBI PORTC,0
            ;------------------------------

			OUT OCR1BH, R2
			OUT OCR1BL, R3
            CALL iniciarT1
			RJMP salir
		contrarioB:
			//Duty cycle 50% - Match
			LDI R16, HIGH(390)
            MOV R2,R16
			OUT OCR1BH, R16
			LDI R16, LOW(390)
            MOV R3,R16
			OUT OCR1BL, R16
			CALL iniciarT1
			RJMP salir

//Interrupción por señal de stop
stop:
	CLR R16
	OUT TCCR0, R16
	OUT TCCR1A, R16
	OUT TCCR1B, R16
	CBI PORTD, 5
	CBI PORTD, 4
	RETI
	
//Subrutina iniciar timer
iniciarT1:
	//Palabra de control T1 - Modo 14, prescaler 1024
	LDI R16, 0b10100010
	OUT TCCR1A, R16
	LDI R16, 0b00011101
	OUT TCCR1B, R16
	RET

;----------LINEAS AGREGADAS----------
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