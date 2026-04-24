/*
 * PostLab05_.c
 *
 * Created: 04/20/2026 12:48:05 PM
 * Author: Paula Ayala
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000
#include <avr/io.h>
#include <avr/interrupt.h>

// Variables 
volatile uint16_t ADC0 = 0;			// Valor potenciómetro (PC0) --> servo1
volatile uint16_t ADC1 = 0;			// Valor potenciómetro (PC1) --> servo2
volatile uint16_t ADC2 = 0;			// Valor potenciómetro (PC2) --> LED 
volatile uint8_t modo = 0;			// Canal activo
volatile uint8_t led_duty = 0;		// Ciclo de trabajo para el LED (0-255)
volatile uint8_t CONTADOR = 0;		// Contador para PWM manual (0-255)

/****************************************/
// Function prototypes
void setup(void);
void init_ADC(void);
void init_PWM1(void);      // Timer1 - servo1 
void init_PWM2(void);      // Timer2 - servo2 
void init_ManualPWM(void); // Timer0 - PWM manual

/****************************************/
// Main Function
int main(void)
{
    cli();               // Deshabilitar interrupciones
    setup();
    init_PWM1();
    init_PWM2();
    init_ManualPWM();
    init_ADC();
    sei();               // Habilitar interrupciones 
    ADCSRA |= (1 << ADSC); // primera conversión 
    while (1)
    {
    }
}

/****************************************/
// NON-Interrupt subroutines

void setup(void)
{
    // Pines de salida
    DDRB |= (1 << PB1) | (1 << PB3);   
    DDRD |= (1 << PD6);                
    PORTB = 0x00;                      
    PORTD = 0x00;
}

// Timer1: PWM - servo1 (PB1)
void init_PWM1(void)
{
    // Fast PWM, TOP = ICR1, salida no inversora
    TCCR1A |= (1 << COM1A1) | (1 << WGM11);
    TCCR1B |= (1 << WGM12) | (1 << WGM13);
    // Prescaler = 64 (16MHz) -> tick = 4 µs.
    TCCR1B |= (1 << CS11) | (1 << CS10);  // prescaler 64
    ICR1 = 5000;      // 20ms
    OCR1A = 125;      // 0.5ms
}

// Timer2: PWM - servo2 (PB3)
void init_PWM2(void)
{
    TCCR2A = 0;
    TCCR2B = 0;
    // Fast PWM (8 bits), no inversor en OC2A
    TCCR2A |= (1 << WGM20) | (1 << WGM21);
    TCCR2A |= (1 << COM2A1);
    // Prescaler = 64 -> tick = 4 µs (igual que Timer1)
    TCCR2B |= (1 << CS21) | (1 << CS20);  // prescaler 64
    OCR2A = 125;      // 0.5 ms
}

// Timer0: PWM manual - LED (PD6)
void init_ManualPWM(void)
{
    // Timer0, Modo normal
    // 16 MHz / 64 = 250 kHz, tick = 4 µs.
    // desbordamiento cada 256 * 4 µs = 1.024 ms 
    TCCR0A = 0;                     // Modo normal
    TCCR0B |= (1 << CS01) | (1 << CS00);  // Prescaler 64
    TIMSK0 |= (1 << TOIE0);         // Habilitar interrupción
}

// ADC (Lectura continua de los 3 canales)
void init_ADC(void)
{
    // Ref AVcc
	// inicio en modo 0 
    ADMUX = (1 << REFS0);
    // Habilitar ADC
	// prescaler 128 (125 kHz) 
    ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0);
    ADCSRA |= (1 << ADIE);   // interrupciones
}

/****************************************/
// Interrupt routines

// ADC
// Luego de finalizar cada conversión
ISR(ADC_vect)
{
    uint16_t VALOR = ADC;   // resultados 10 bits

    switch (modo)
    {
        case 0:
            ADC0 = VALOR;
            // Mapeo  (0-1023) a (125-625) --> (0.5 ms - 2.5 ms) SERVO1
            OCR1A = 125 + ((uint32_t)VALOR * 500) / 1023;
            break;
        case 1:
            ADC1 = VALOR;
            // Mapeo (0-1023) a (0-255) --> (0-1.02 ms) SERVO2
            OCR2A = ((uint32_t)VALOR * 255) / 1023;
            break;
        case 2:
            ADC2 = VALOR;
            // Mapeo (0-1023) a (0-255) --> ciclo de trabajo del LED
            led_duty = ((uint32_t)VALOR * 255) / 1023;
            break;
    }

    // Cambio de modo
    modo = (modo + 1) % 3;
    ADMUX = (ADMUX & 0xF0) | modo;		// Cambiar multiplexor del ADC
    ADCSRA |= (1 << ADSC);				// Iniciar la siguiente conversión
}

// Interrupción Timer0 (PWM manual) 
ISR(TIMER0_OVF_vect)
{
    // Al inicio del ciclo (CONTADOR == 0) entonces = pin en alto
    if (CONTADOR == 0)
    {
        PORTD |= (1 << PD6);
    }
    CONTADOR++;
    if (CONTADOR >= 256)
    {
        CONTADOR = 0;
    }
    // Cuando el contador alcanza el valor de duty, se apaga el led
    if (CONTADOR == led_duty)
    {
        PORTD &= ~(1 << PD6);
    }
}
