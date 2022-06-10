;PRUEBA DE ADC 2 EN C

#DEFINE F_CPU 20000000
#include <avr/io.h>
#include <util/delay.h>

int main(void){
    DDRD = 0xFF
    DDRA |= (0<<DDD0) ;PENDIENTE
    ADCSRA = 0x87
    ADMUX = 0xC0

    WHILE(1){
        ADCSRA |= (A<<ADSC)
        while ((ADCSRA&(1<<ADIF))==0)
        PORTD = ADCL


    }
    return 0
}