.INCLUDE "m328PdeF.inc"


LDI R16,HIGH(RAMEND)
OUT SPH,R16
LDI R16,LOW(RAMEND)
OUT SPL,R16


;INPUT FOR THE ADC
CBI DDRA,0
SER R16
LDI DDRB,R16
LDI DDRD,R16

;ENABLE ADC AND SELECT CK =128
LDI R16,0b10000111
OUT ADCSRA,R16

;2.56 Vrfe,ADC0 single ended, rigth justified data
LDI R16,0b11000000
OUT ADMUX,R16

READ_ADC:
    SBI ADCSRA,ADSC

    KEEP_POLLING:
        SBIS ADCSRA,ADIF
        RJMP KEEP_POLLING
        SBI ADCSRA,ADIF
        IN R16,ADCL
        OUT PORTB,R16
        IN R16,ADCH
        OUT PORTD,R16
RJMP READ_ADC

