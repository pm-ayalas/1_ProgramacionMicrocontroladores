/*
 * PostLab_04_Adaptado.c
 * Adaptado para nuevo circuito:
 * - Botones PC0 (decremento), PC1 (incremento) con pull-up (presionado=0)
 * - Potenciómetro en PC2 (ADC2)
 * - Displays y LEDs activo alto (1 enciende)
 * - Transistores: PB1 (LEDs), PB2 (decenas), PB3 (unidades)
 * - LED alarma PB0
 * - Tabla de segmentos SEGMENT_MAP (activo alto)
 */

#include <avr/io.h>
#include <avr/interrupt.h>

#define T1Value 0x004E  // CTC 5ms

volatile uint8_t Valor_ADC = 0;
volatile uint8_t CONTADOR_LEDs = 0;
volatile uint8_t BANDERA_BTN_incremento = 0;
volatile uint8_t BANDERA_BTN_decremento = 0;

volatile uint8_t prev_PC0 = 1;
volatile uint8_t prev_PC1 = 1;

volatile uint8_t TRANSISTOR = 0;  // 0=LEDs, 1=decenas, 2=unidades

volatile uint8_t patron_unidades = 0x7E;  // inicial '0' según nueva tabla
volatile uint8_t patron_decenas  = 0x7E;

// Nueva tabla de segmentos (activo alto, 1 enciende)
const uint8_t SEGMENT_MAP[16] = {
    0x7E,0x30,0x6D,0x79,0x33,0x5B,0x5F,0x70,
    0x7F,0x7B,0x77,0x1F,0x4E,0x3D,0x4F,0x47
};

void setup(void);
void init_ADC(void);
void init_TMR1(void);
void init_PinChange(void);

int main(void) {
    cli();
    setup();
    init_PinChange();
    init_ADC();
    init_TMR1();
    sei();

    ADCSRA |= (1 << ADSC);  // primera conversión

    while (1) {
        if (BANDERA_BTN_incremento) {
            BANDERA_BTN_incremento = 0;
            CONTADOR_LEDs++;
        }
        if (BANDERA_BTN_decremento) {
            BANDERA_BTN_decremento = 0;
            CONTADOR_LEDs--;
        }
    }
}

void setup(void) {
    CLKPR = (1 << CLKPCE);
    CLKPR = (1 << CLKPS2);   // 1 MHz

    UCSR0B = 0x00;  // apagar UART

    // PORTD: salida para LEDs y segmentos (activo alto)
    DDRD = 0xFF;
    PORTD = 0x00;   // inicial apagados (0)

    // PORTB: transistores PB1(LEDs), PB2(decenas), PB3(unidades) y alarma PB0
    DDRB |= (1 << PB0) | (1 << PB1) | (1 << PB2) | (1 << PB3);
    PORTB &= ~((1 << PB0) | (1 << PB1) | (1 << PB2) | (1 << PB3)); // todos apagados

    // Botones PC0, PC1 con pull-up; potenciómetro PC2 (entrada analógica)
    DDRC &= ~((1 << PC0) | (1 << PC1) | (1 << PC2));
    PORTC |= (1 << PC0) | (1 << PC1);  // pull-ups botones
}

void init_PinChange(void) {
    PCICR |= (1 << PCIE1);           // habilitar PCINT1 (Puerto C)
    PCMSK1 |= (1 << PCINT8) | (1 << PCINT9); // PC0 y PC1
}

void init_TMR1(void) {
    TCCR1B = 0;
    TCCR1B |= (1 << WGM12);          // CTC
    TCCR1B |= (1 << CS11) | (1 << CS10); // prescaler 64
    OCR1A = T1Value;
    TIMSK1 |= (1 << OCIE1A);
    TCNT1 = 0;
}

void init_ADC(void) {
    ADMUX = 0;
    // Referencia AVcc, justificación izquierda (ADLAR=1), canal ADC2 (PC2)
    // MUX bits: ADC2 = 0010 -> MUX1=1
    ADMUX |= (1 << REFS0) | (1 << ADLAR) | (1 << MUX1);
    ADCSRA = 0;
    ADCSRA |= (1 << ADEN) | (1 << ADPS1) | (1 << ADPS0); // prescaler 8
    ADCSRA |= (1 << ADIE);            // interrupción ADC
}

ISR(PCINT1_vect) {
    uint8_t estado = PINC;
    uint8_t actual_PC0 = (estado >> PC0) & 1;
    if ((prev_PC0 == 1) && (actual_PC0 == 0))
        BANDERA_BTN_decremento = 1;
    prev_PC0 = actual_PC0;

    uint8_t actual_PC1 = (estado >> PC1) & 1;
    if ((prev_PC1 == 1) && (actual_PC1 == 0))
        BANDERA_BTN_incremento = 1;
    prev_PC1 = actual_PC1;
}

ISR(TIMER1_COMPA_vect) {
    // Apagar todos los transistores
    PORTB &= ~((1 << PB1) | (1 << PB2) | (1 << PB3));

    switch (TRANSISTOR) {
        case 0: // LEDs
            PORTD = CONTADOR_LEDs;   // activo alto, sin invertir
            PORTB |= (1 << PB1);
            break;
        case 1: // decenas (nibble alto)
            PORTD = patron_decenas;
            PORTB |= (1 << PB2);
            break;
        case 2: // unidades (nibble bajo)
            PORTD = patron_unidades;
            PORTB |= (1 << PB3);
            break;
    }

    TRANSISTOR++;
    if (TRANSISTOR >= 3) TRANSISTOR = 0;

    // Alarma: comparar Valor_ADC con CONTADOR_LEDs (ambos 0-255)
    if (Valor_ADC > CONTADOR_LEDs)
        PORTB |= (1 << PB0);
    else
        PORTB &= ~(1 << PB0);
}

ISR(ADC_vect) {
    Valor_ADC = ADCH;   // 8 bits justificados a la izquierda
    uint8_t nibble_alto = (Valor_ADC >> 4) & 0x0F;
    uint8_t nibble_bajo = Valor_ADC & 0x0F;
    patron_decenas = SEGMENT_MAP[nibble_alto];
    patron_unidades = SEGMENT_MAP[nibble_bajo];
    ADCSRA |= (1 << ADSC);   // iniciar siguiente conversión
}