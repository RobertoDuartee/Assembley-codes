.INCLUDE "m16def.inc"
.DEF TEMP=R20
.DEF TIDA=R19
.ORG 0
	RJMP MAIN
.ORG 2
	RJMP ENTER   //BOTON
.ORG 4
	RJMP TECLADO_M

MAIN:
//PILA
LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16
SER R16
OUT DDRC,R16
//PUNTERO PARA GUARDAR DATOS DEL PACIENTE
SBI DDRD,7
LDI YL,LOW(0x60)
LDI YH,HIGH(0x60)
LDI ZL,LOW(0X300<<1)
LDI ZH,HIGH(0X300<<1)

LDI R16,2 //dígitos
STS 0x100,R16
LDI R16,1
STS 0x101,R16
LDI R16,4
STS 0x102,R16
LDI R16,10
STS 0x103,R16
LDI TIDA,255
CALL INITLCD_4BITS
SET
//POLLING DEL SWITCH DE ENCENDIDO
PO:
SBIC PINA,4              //SWITCH
	RJMP DALE
CLR R16
OUT GICR,R16
OUT TIMSK,R16
OUT MCUCR,R16
//APAGAR ALARMA
//LIMPIAR LCD

RJMP PO
DALE:
//SERIAL
SBI DDRD,1
LDI R16,0b10000110
OUT UCSRC,R16
LDI R16,0b00001000
OUT UCSRB,R16
LDI R16,51
OUT UBRRL,R16

//PALABRAS DE CONTROL
LDI R16,0b11000000   //INTERRUPCION 0
OUT GICR,R16
LDI R16,0b00000010   //TIMER 0 (COMPARE)
OUT TIMSK,R16
LDI R16,0b00001111   //FLANCO DE SUBIDA
OUT MCUCR,R16
SEI
CLR R16
STS 0X200,R16
FIN:RJMP FIN
//FIN MAIN
// ---------PWM--TIMER1----------------------------------------------------------------------------
PWM:
LDI R16, HIGH (23436)
OUT OCR1AH, R16
LDI R16, LOW (23436)
OUT OCR1AL, R16

LDI R16, HIGH(11718)
OUT OCR1BH, R16
LDI R16, LOW(11718)
OUT OCR1BH, R16
LDI R16, 0B00100011
OUT TCCR1A, R16

LDI R16, 0B00011101
OUT TCCR1B, R16
RET
// ---------CONTADOR PULSOS-----------------------------------------------------------------------

LDI R16, 3
OUT OCR0, R16
LDI R16,0b00001110
OUT TCCR0, R16
Poll: 
IN R16, TIFR
SBRS R16, OCF0
RJMP Poll

CLR R16
OUT TCCR0, R16
LDI R16, 1<<OCF0 
OUT TIFR, R16



//--------------------------------UNIDAD DE CAPTURA-------------------
//-------------LOW BYTE 0x300, HIGH BYTE 0X301

UCAPT:
CLR R16
OUT TCCR1A,R16
LDI R16,0b00000101
OUT TCCR1B,R16

AGAIN:   //REVISAR
IN R16,TIFR
SBRS R16,ICF1
RJMP AGAIN

IN R16, ICR1L
STS 0x300,R20
IN R16,ICR1H
STS 0x301,R16

LDI R16,1<<ICF1
OUT TIFR,R16
LDI R16,0b01000101
OUT TCCR1B,R16

AGAIN1:
IN R16,TIFR
SBRS R16,ICF1
RJMP AGAIN1

IN R16, ICR1L
STS 0x302,R20
IN R16,ICR1H
STS 0x303,R16

LDS R16,0x300
LDS R17,0x302
SUB R17,R16
LDS R18,0x301
LDS R19,0x303
SBC R19,R18

STS 0x300,R17
STS 0x301,R19
LPM R18,Z
CP R17,R18
BRSH PELIGRO
GET_OUT:
RET
PELIGRO:
CALL PWM
RJMP GET_OUT


//----------LCD-------------------------------------------------------------------------------
INITLCD_4BITS:
LDI R25,0x28    //FUNCTION SET
CLT
CALL SENDLCD_4BITS
CALL delay10ms
LDI R25,0x0F    //DISPLAY ON CURSOR BLINKING
CALL SENDLCD_4BITS
CALL delay10ms
LDI R25,0x01    //CLEAR DISPLAY
CALL SENDLCD_4BITS
CALL delay10ms
RET

SENDLCD_4BITS:
MOV TEMP, R25
ANDI TEMP,0b11110000
BLD R17,0
SBRS R17,0
	RJMP INSTR
LDI R21,0b00000110 //T=1
LDI R22,0b00000001
ADD TEMP,R21
RJMP SIGUE
INSTR:
LDI R21,0b00000100 //T=0
LDI R22,0b00000000 
ADD TEMP,R21
SIGUE:
OUT PORTC,TEMP
ANDI TEMP,0b11110000
ADD TEMP,R22
OUT PORTC,TEMP
CALL delay40us
LDI R22,4
ADD TEMP,R22
OUT PORTC,TEMP
CALL delay40us
MOV TEMP, R25
SWAP TEMP
ANDI TEMP,0b11110000
BLD R17,0
SBRS R17,0
	RJMP INST
LDI R21,0b00000110 //T=1
LDI R22,0b00000001
ADD TEMP,R21
RJMP SIGUE2
INST:
LDI R21,0b00000100 //T=0
LDI R22,0b00000000 
ADD TEMP,R21
SIGUE2:
OUT PORTC,TEMP
ANDI TEMP,0b11110000
ADD TEMP,R22
OUT PORTC,TEMP
CALL delay40us
LDI R22,4
ADD TEMP,R22
OUT PORTC,TEMP
CALL delay40us
RET
	
//--------DELAYs----------------------------------------------------------------------------------------
delay500us: 
PUSH R16
LDI R16,4
OUT OCR0,R16
LDI R16, 0b00001001
OUT TCCR0,R16
CLR R16
OUT TCNT0,R16
POLL500U: IN R16,TIFR
	SBRS R16,OCF0
	RJMP POLL500U
CLR R16
OUT TCCR0,R16
LDI R16,1<<OCF0
OUT TIFR,R16
POP R16
RET

delay10ms:PUSH R16
LDI R16,77
OUT OCR0,R16
LDI R16,0b00001101
OUT TCCR0,R16
CLR R16
OUT TCNT0,R16
POLL10: IN R16,TIFR
	SBRS R16,OCF0
	RJMP POLL10
CLR R16
OUT TCCR0,R16
LDI R16,1<<OCF0
OUT TIFR,R16
POP R16
RET

delay40us: PUSH R19
CLR R19
OUT TCNT0,R19
LDI R19,39
OUT OCR0,R19
LDI R19,0b00001010
OUT TCCR0,R19
POLLC: IN R19,TIFR
	SBRS R19,OCF0
	RJMP POLLC
CLR R19
OUT TCCR0,R19
LDI R19,1<<OCF0
OUT TIFR,R19
POP R19
RET

delay1ms:
PUSH R16
LDI R16,8
OUT OCR0,R16
LDI R16, 0b00001001
OUT TCCR0,R16
POLL1: IN R16,TIFR
	SBRS R16,TOV0
	RJMP POLL1
CLR R16
OUT TCCR0,R16
LDI R16,1<<TOV0
OUT TIFR,R16
POP R16
RET

//---------------------INTERUPCCION EXTERNA 0 (BOTON)--------------------
// CAMBIAR EL TIPO DE ENTRADA DE DATO: 0- EDAD 1- GÉNERO 2- #PACIENTE 3-FECHA 4- VISUALIZAR
ENTER:
IN R16,SREG
PUSH R16
//PALABRA DE CONTROL TECLA
INC TIDA
CPI TIDA,0
	BREQ DATO_EDAD
CPI TIDA,1
	BREQ DATO_GEN
CPI TIDA,2
	BREQ NUM_PACIENTE1
CPI TIDA,3
	BREQ FECHAA
CPI TIDA,4
	BREQ VISUALIZARR
SALIR:
POP R16
OUT SREG,R16
RETI
FECHAA:JMP FECHA
VISUALIZARR:JMP VISUALIZAR

NUM_PACIENTE1:JMP NUM_PACIENTE
DATO_EDAD:
LDI XL,LOW(0x200)
LDI XH,HIGH(0x200)
CLT
CALL INITLCD_4BITS
SET
LDI R25,'E'
CALL SENDLCD_4BITS
LDI R25,'D'
CALL SENDLCD_4BITS
LDI R25,'A'
CALL SENDLCD_4BITS
LDI R25,'D'
CALL SENDLCD_4BITS
LDI R25,':'
CALL SENDLCD_4BITS
RJMP SALIR
DATO_GEN:
LDI XL,LOW(0x203)
LDI XH,HIGH(0x203)
CLT
CALL INITLCD_4BITS
SET
LDI R25,'G'
CALL SENDLCD_4BITS
LDI R25,'E'
CALL SENDLCD_4BITS
LDI R25,'N'
CALL SENDLCD_4BITS
LDI R25,'E'
CALL SENDLCD_4BITS
LDI R25,'R'
CALL SENDLCD_4BITS
LDI R25,'O'
CALL SENDLCD_4BITS
LDI R25,':'
CALL SENDLCD_4BITS
RJMP SALIR
NUM_PACIENTE:
LDI XL,LOW(0x204)
LDI XH,HIGH(0x204)
CLT
CALL INITLCD_4BITS
SET 
LDI R25,'#'
CALL SENDLCD_4BITS
LDI R25,'P'
CALL SENDLCD_4BITS
LDI R25,'A'
CALL SENDLCD_4BITS
LDI R25,'C'
CALL SENDLCD_4BITS
LDI R25,'I'
CALL SENDLCD_4BITS
LDI R25,'E'
CALL SENDLCD_4BITS
LDI R25,'N'
CALL SENDLCD_4BITS
LDI R25,'T'
CALL SENDLCD_4BITS
LDI R25,'E'
CALL SENDLCD_4BITS
LDI R25,':'
CALL SENDLCD_4BITS
RJMP SALIR
FECHA:
LDI XL,LOW(0x208)
LDI XH,HIGH(0x208)
CLT
CALL INITLCD_4BITS
SET
LDI R25,'F'
CALL SENDLCD_4BITS
LDI R25,'E'
CALL SENDLCD_4BITS
LDI R25,'C'
CALL SENDLCD_4BITS
LDI R25,'H'
CALL SENDLCD_4BITS
LDI R25,'A'
CALL SENDLCD_4BITS
LDI R25,':'
CALL SENDLCD_4BITS
RJMP SALIR
VISUALIZAR:
CLT
CALL INITLCD_4BITS               //---------------------PRUEBA LIMPIAR LCD
SET
LDI R25,'#'
CALL SENDLCD_4BITS
LDI R25,':'
CALL SENDLCD_4BITS
LDS R25,0X204
CALL SENDLCD_4BITS
LDS R25,0X205
CALL SENDLCD_4BITS
LDS R25,0X206
CALL SENDLCD_4BITS
LDS R25,0X207
CALL SENDLCD_4BITS
CLT
LDI R25,0x87
CALL SENDLCD_4BITS
SET
LDI R25,'G'
CALL SENDLCD_4BITS
LDI R25,':'
CALL SENDLCD_4BITS
LDS R25,0X203
CALL SENDLCD_4BITS
CLT
LDI R25,0x8B
CALL SENDLCD_4BITS
SET
LDI R25,'E'
CALL SENDLCD_4BITS
LDI R25,':'
CALL SENDLCD_4BITS
LDS R25,0X201
CALL SENDLCD_4BITS
LDS R25,0X200
CALL SENDLCD_4BITS
CLT
LDI R25,0xC0
CALL SENDLCD_4BITS
SET
LDI R25,'F'
CALL SENDLCD_4BITS
LDI R25,':'
CALL SENDLCD_4BITS
LDS R25,0X208
CALL SENDLCD_4BITS
LDS R25,0X209
CALL SENDLCD_4BITS
LDS R25,0X20A
CALL SENDLCD_4BITS
LDS R25,0X20B
CALL SENDLCD_4BITS
LDS R25,0X20C
CALL SENDLCD_4BITS
LDS R25,0X20D
CALL SENDLCD_4BITS
LDS R25,0X20E
CALL SENDLCD_4BITS
LDS R25,0X20F
CALL SENDLCD_4BITS
LDS R25,0X210
CALL SENDLCD_4BITS
LDS R25,0X211
CALL SENDLCD_4BITS
LDI TIDA,255 
RJMP SALIR
//-------------TECLA PRESIONADA
TECLADO_M:
IN R16,SREG
PUSH R16
SBI PORTD,7
IN R16,PINA
ANDI R16,0x0F
CALL CONV_TECLA
CPI TIDA,0
	BREQ CERO
CPI TIDA,1
	BREQ UNO
CPI TIDA,2
	BREQ DOS
CPI TIDA,3
	BREQ TRES
CERO:
ST X+,R16
LDS R17,0x100
DEC R17
STS 0X100,R17
CPI R17,0
BRNE SALIRTT
LDI R17,2
STS 0X100,R17
LDI XL,LOW(0x200)
LDI XH,HIGH(0x200)
RJMP SALIRTT
UNO:
ST X,R16
LDS R17,0x101
DEC R17
STS 0X101,R17
CPI R17,0
BRNE SALIRTT
LDI R17,1
STS 0X101,R17
LDI XL,LOW(0x203)
LDI XH,HIGH(0x203)
RJMP SALIRTT
DOS:
ST X+,R16
LDS R17,0x102
DEC R17
STS 0X102,R17
CPI R17,0
BRNE SALIRTT
LDI R17,4
STS 0X102,R17
LDI XL,LOW(0x204)
LDI XH,HIGH(0x204)
RJMP SALIRTT
TRES: 
ST X+,R16
LDS R17,0x103
DEC R17
STS 0X103,R17
CPI R17,0
BRNE SALIRTT
LDI R17,10
STS 0X103,R17
LDI XL,LOW(0x208)
LDI XH,HIGH(0x208)
SALIRTT:
POP R16
OUT SREG,R16
RETI

//CONVERSION TECLAS
CONV_TECLA:
PUSH R17
CPI R16,3
BRLO SUMT
BREQ DIV
CPI R16,7
BREQ MULT
CPI R16,8
BREQ UUNO
CPI R16,9
BREQ NUEVE
CPI R16,10
BREQ TREES
CPI R16,11
BREQ NEGA
CPI R16,13
BREQ CER
CPI R16,14
BREQ EQU
CPI R16,15
BREQ MASS
LDI R17,0X30
ADD R16,R17
RJMP EXITE
NUEVE:
LDI R16,0x32
RJMP EXITE
UUNO:
LDI R16,0x31
RJMP EXITE
MULT:
LDI R16,0x2A
RJMP EXITE
DIV:
LDI R16,0x2F
RJMP EXITE
TREES:
LDI R16,0x33
RJMP EXITE
SUMT:
LDI R17,0x37
ADD R16,R17
RJMP EXITE
EQU:
CPI TIDA,4
BREQ TX
RJMP EXITE
CER:
LDI R16,0x30
RJMP EXITE
NEGA:
LDI R16,0x2D
RJMP EXITE
MASS:
LDI R16,0x2B
EXITE:
POP R17
RET
//-------------------------------COMUNICACION SERIAL----------------
TX:
LDI XL,LOW(0X200)
LDI XH,HIGH(0X200)
LDI R16,17
CICLE: LD R17,X+
OUT UDR,R17
POLLINGTX: SBIS UCSRA,UDRE
	RJMP POLLINGTX
DEC R16
BRNE CICLE
CALL UCAPT
RJMP EXITE




.ORG 0x400
.DB 3,0

/*
RX: IN R16,SREG
PUSH R16
IN R16,UDR
ST Y+,R16
DEC CONT_RX
BRNE SALIR

POP R16
SALIR: OUT SREG,R16
RETI
*/

