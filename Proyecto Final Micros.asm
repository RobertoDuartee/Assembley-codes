.INCLUDE "m16def.inc"
.DEF TEMP=R20
.DEF TIDA=R19
.DEF INT_RE=R23
.ORG 0
	RJMP MAIN
.ORG 2
	RJMP ENTER   //BOTON
.ORG 4
	RJMP TECLADO_M
.ORG 0x6
	RJMP TIMER_2

MAIN:
//PILA
LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16
SER R16
OUT DDRC,R16
LDI INT_RE,3
//PUNTERO PARA GUARDAR DATOS DEL PACIENTE
SBI DDRD,7
SBI DDRD,4
SBI DDRD,1
LDI YL,LOW(0x60)
LDI YH,HIGH(0x60)

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
//POLLING DEL SWITCH DE ENCENDIDO
PO:
SBIC PINA,4              //SWITCH
	RJMP DALE
CLR R16
OUT GICR,R16
OUT TIMSK,R16
OUT MCUCR,R16
CALL INITLCD_4BITS
//APAGAR ALARMA
//LIMPIAR LCD

RJMP PO
DALE:

//SERIAL
LDI R16,0b10000110
OUT UCSRC,R16
LDI R16,0b00001000
OUT UCSRB,R16
LDI R16,51
OUT UBRRL,R16

//PALABRAS DE CONTROL
LDI R16,0b01000000   //INTERRUPCION 0
OUT GICR,R16
LDI R16,0b10000000   //TIMER 0 (COMPARE)
OUT TIMSK,R16
LDI R16,0b00001111   //FLANCO DE SUBIDA
OUT MCUCR,R16
SEI
ldi R16,5
STS 0X200,R16
BST R16,0
FIN:RJMP FIN
//FIN MAIN
// ---------PWM--TIMER1----------------------------------------------------------------------------
PWM:
LDI R16, HIGH (15624)
OUT OCR1AH, R16
LDI R16, LOW (15624)
OUT OCR1AL, R16

LDI R16, HIGH(7811)
OUT OCR1BH, R16
LDI R16, LOW(7811)
OUT OCR1BL, R16
LDI R16, 0b00100011
OUT TCCR1A, R16
LDI R16, 0b00011101
OUT TCCR1B, R16
CALL DELAY1S
RET
// ---------CONTADOR PULSOS-----------------------------------------------------------------------

LDI R16, 3
OUT OCR2, R16
LDI R16,0b00001110
OUT TCCR2, R16
Poll: 
IN R16, TIFR
SBRS R16, OCF2
RJMP Poll

CLR R16
OUT TCCR2, R16
LDI R16, 1<<OCF0 
OUT TIFR, R16


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
delay500us: PUSH R19
PUSH R20
LDI R19,7
LOOP1: LDI R20,255
LOOP2: DEC R20
BRNE LOOP2
DEC R19
BRNE LOOP1
POP R20
POP R19
RET

delay10ms:PUSH R19
PUSH R20
LDI R19,104
LOOP3: LDI R20,255
LOOP4: DEC R20
BRNE LOOP4
DEC R19
BRNE LOOP3
POP R20
POP R19
RET

delay40us: PUSH R19
PUSH R20
LDI R19,1
LOOP5: LDI R20,120
LOOP6: DEC R20
BRNE LOOP6
DEC R19
BRNE LOOP5
POP R20
POP R19
RET

delay1ms: PUSH R19
PUSH R20
LDI R19,10
LOOP7: LDI R20,255
LOOP8: DEC R20
BRNE LOOP8
DEC R19
BRNE LOOP7
POP R20
POP R19
RET

DELAY3S:
PUSH R22
PUSH R24
LDI R24,30
LOOPD:LDI R22,10
LOOPC:CALL delay10ms
DEC R22
BRNE LOOPC
DEC R24
BRNE LOOPD
POP R24
POP R22
RET
DELAY1S:
PUSH R26
PUSH R27
LDI R27,10
LOOPE:LDI R26,10
LOOPF:CALL delay10ms
DEC R26
BRNE LOOPF
DEC R27
BRNE LOOPE
POP R27
POP R26
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
LDI R16,0b11000000   //INTERRUPCION 1
OUT GICR,R16
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
CALL INITLCD_4BITS               
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
LDS R25,0X200
CALL SENDLCD_4BITS
LDS R25,0X201
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
IN R16,PINA
ANDI R16,0x0F
CALL CONV_TECLA
MOV R25,R16
SET
CALL SENDLCD_4BITS          //PROBANDO
CPI TIDA,0
	BREQ CERO
CPI TIDA,1
	BREQ UNO
CPI TIDA,2
	BREQ DOS
CPI TIDA,3
	BREQ TRES
RJMP SALIRTT
CERO:
ST X+,R16
LDS R17,0x100
DEC R17
STS 0X100,R17
CPI R17,0
BRNE SALIRTTT
LDI R17,2
STS 0X100,R17
LDI XL,LOW(0x200)
LDI XH,HIGH(0x200)
CLT
LDI R25,0x85
CALL SENDLCD_4BITS
SET
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
CLT
LDI R25,0x87
CALL SENDLCD_4BITS
SET
RJMP SALIRTT
SALIRTTT:RJMP SALIRTT
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
CLT
LDI R25,0x8A
CALL SENDLCD_4BITS
SET
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
CLT
LDI R25,0x86
CALL SENDLCD_4BITS
SET
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
CPI TIDA,255
BREQ TX
RJMP EXITE
CER:
LDI R16,0x30
RJMP EXITE
NEGA:
LDI R16,'H'
RJMP EXITE
MASS:
LDI R16,'M'
EXITE:
POP R17
RET
//-------------------------------COMUNICACION SERIAL----------------
TX:  //CAMBIAR A INTERRUPCIÓN
LDI XL,LOW(0X200)
LDI XH,HIGH(0X200)
LDI R16,18
CICLE: LD R17,X+
OUT UDR,R17
POLLINGTX: SBIS UCSRA,UDRE
	RJMP POLLINGTX
SBI PORTD,7
DEC R16
BRNE CICLE
LDI R16,77
OUT OCR2,R16
LDI R16,0b00001101
OUT TCCR2,R16
RJMP EXITE

TIMER_2:
CALL CONT_PULSOS
RETI

CONT_PULSOS:
LDI R16,0b00000111
OUT TCCR0,R16
CLR R16
OUT TCNT0,R16
CALL DELAY3S
IN R16,TCNT0
CPI R16,2
	BRLO DESPEJEN
CLR R16
LDI INT_RE,3
OUT TCCR1A, R16
OUT TCCR1B, R16
ADEU:
RET

DESPEJEN:
CALL PWM
DEC INT_RE          //DECREMENTAR INTENTOS DE REANIMACIÓN
BRNE ADEU
//PACIENTE MUERTO
LDI R16,0b00000000
OUT TCCR0,R16
CLR R16
OUT TCCR1A, R16
OUT TCCR1B, R16
CLT
CALL INITLCD_4BITS
SET 
LDI R25,'R'
CALL SENDLCD_4BITS
LDI R25,'E'
CALL SENDLCD_4BITS
LDI R25,'A'
CALL SENDLCD_4BITS
LDI R25,'N'
CALL SENDLCD_4BITS
LDI R25,'I'
CALL SENDLCD_4BITS
LDI R25,'M'
CALL SENDLCD_4BITS
LDI R25,'A'
CALL SENDLCD_4BITS
LDI R25,'C'
CALL SENDLCD_4BITS
LDI R25,'I'
CALL SENDLCD_4BITS
LDI R25,'O'
CALL SENDLCD_4BITS
LDI R25,'N'
CALL SENDLCD_4BITS
CLT
LDI R25,0xC0
CALL SENDLCD_4BITS
SET
LDI R25,'F'
CALL SENDLCD_4BITS
LDI R25,'A'
CALL SENDLCD_4BITS
LDI R25,'L'
CALL SENDLCD_4BITS
LDI R25,'L'
CALL SENDLCD_4BITS
LDI R25,'I'
CALL SENDLCD_4BITS
LDI R25,'D'
CALL SENDLCD_4BITS
LDI R25,'A'
CALL SENDLCD_4BITS
LDI R16,0b00000000   //DESACTIVAR INTERRUPCIOND DE TIMER 2
OUT TIMSK,R16
RJMP ADEU


