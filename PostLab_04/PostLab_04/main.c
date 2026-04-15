/*
 * PostLab_04.c
 *
 * Created: 4/12/2026 8:18:44 PM
 * Author: Paula Ayala
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#include <avr/io.h>
#include <avr/interrupt.h>

// VARIABLES
#define T1Value 0x004E // CTC 5ms

volatile uint8_t Valor_ADC = 0;
volatile uint8_t CONTADOR_LEDs = 0;
volatile uint8_t BANDERA_BTN_incremento = 0;
volatile uint8_t BANDERA_BTN_decremento = 0;

volatile uint8_t prev_PC0 = 1;  
volatile uint8_t prev_PC1 = 1;

volatile uint8_t TRANSISTOR = 0;	// 0=LEDs 1=DisplayUnidades 2=DisplayDecenas

// inicio en 00 
volatile uint8_t patron_unidades = 0x40;
volatile uint8_t patron_decenas = 0x40;

const uint8_t SEGMENTOS[16] = {
    0x40,    // 0
    0x75,    // 1
    0x22,    // 2
    0x24,    // 3
    0x15,    // 4
    0x0C,    // 5
    0x08,    // 6
    0x65,    // 7
    0x00,    // 8
    0x05,    // 9
    0x01,    // A
    0x18,    // b
    0x4A,    // C
    0x30,    // d
    0x0A,    // E
    0x0B	 // F
};

/****************************************/
// Function prototypes
void setup(void);
void init_ADC(void);
void init_TMR1(void);
void init_PinChange(void);

/****************************************/
// Main Function
int main(void)
{
	cli();
	setup();
	init_PinChange();
	init_ADC();
	init_TMR1();
	sei();
	
	// Iniciar primera conversión ADC
	ADCSRA |= (1 << ADSC);
		
	while (1){
		
		// Verificar banderas btns
		if (BANDERA_BTN_incremento){
			BANDERA_BTN_incremento = 0;	// restablecer
			CONTADOR_LEDs++;
		}
		if (BANDERA_BTN_decremento){
			BANDERA_BTN_decremento = 0;	// restablecer
			CONTADOR_LEDs--;
		}
		
		
	}
}

/****************************************/
// NON-Interrupt subroutines
void setup(void){
	// Definir frecuencia de Reloj 1MHz
	CLKPR	= (1<<CLKPCE);
	CLKPR	= (1<<CLKPS2);
	
	UCSR0B	= 0x00;	// Apagar pines por UART
	
	// PORTD -> Salida [LEDs + Display]
	DDRD	= 0xFF;
	PORTD	= 0xFF;           // Apagados

	// PORTB -> Salida [Transistores]
	DDRB	|= (1 << PINB1) | (1 << PINB2) | (1 << PINB3) | (1 << PINB0);
	PORTB &= ~((1 << PB1) | (1 << PB2) | (1 << PB3) | (1 << PB0)); // todos apagados

	// PC0,PC1 -> Entrada [Botones] pull-up - [Potenciometro]
	DDRC	&= ~((1 << PC0) | (1 << PC1) | (1 << PC5));
	PORTC	|= (1 << PC0) | (1 << PC1);
}

void init_PinChange(void){
	// Habilitar interrupciones para PCINT1 (PORTC)
	PCICR |= (1 << PCIE1);
	// PC0 (PCINT8) - PC1 (PCINT9)
	PCMSK1 |= (1 << PCINT8) | (1 << PCINT9);
}

void init_TMR1(void){

	TCCR1B = 0;
	
	// Modo CTC
	TCCR1B |= (1 << WGM12);
	// Prescaler 64
	TCCR1B |= (1 << CS11) | (1 << CS10);
	// Valor para comparación 
	OCR1A = T1Value;
	// Habilitar interrupción
	TIMSK1 |= (1 << OCIE1A);
	TCNT1 = 0; // Iniciar contador en 0
}

void init_ADC(void){
	ADMUX	= 0;
	// Aref = AVcc; Justificacion a la izquierda; Pin PC5 (ADC5)
	ADMUX	|= (1<<REFS0) | (1<<ADLAR) | (1<<MUX2) | (1<<MUX0);
	
	ADCSRA	= 0;
	// Habilitar ADC y seleccionar prescaler = 8 -- 1MHz/8=125kHz
	ADCSRA	|= (1<<ADEN) | (1<<ADPS1) | (1<<ADPS0);
	ADCSRA	|= (1 << ADIE);	// Hab interrupciones
}

/****************************************/
// Interrupt routines

ISR(PCINT1_vect){
	// Leer PORTC
	uint8_t estado_actual = PINC;
	
	// Selección de pin específico y máscara
	uint8_t actual_PC0 = (estado_actual >> PC0) & 1;
	
	if ((prev_PC0 == 1) && (actual_PC0 == 0)){
		BANDERA_BTN_decremento = 1;
	}
	prev_PC0 = actual_PC0; // Actualizar estado
	
	// Selección de pin específico y máscara
	uint8_t actual_PC1 = (estado_actual >> PC1) & 1;
	
	if ((prev_PC1 == 1) && (actual_PC1 == 0)){
		BANDERA_BTN_incremento = 1;
	}
	prev_PC1 = actual_PC1; // Actualizar estado
	
}

ISR(TIMER1_COMPA_vect){
	// Actualizar transistor - PORTB
	PORTB &= ~((1 << PB1) | (1 << PB2) | (1 << PB3)); // apagar todos
	
	// Encender seleccionado
	switch (TRANSISTOR){
		case 0:		// LEDS
			PORTD = ~CONTADOR_LEDs; 
			PORTB |= (1 << PB1); 
			break;
		case 1:		// DISPLAY unidades (nibble bajo)
			PORTD = patron_unidades;
			PORTB |= (1 << PB2); 
			break;
		case 2:		// DISPLAY decenas (nibble alto)
			PORTD = patron_decenas;
			PORTB |= (1 << PB3); 
			break;
	}
	
	// Cambiar transistor
	TRANSISTOR++;
	if (TRANSISTOR == 3){
		TRANSISTOR = 0;
	}
	
	// Comparación Contador y Lectura ADC
	if (Valor_ADC > CONTADOR_LEDs) {
		PORTB |= (1 << PB0);   // enciende LED
		} else {
		PORTB &= ~(1 << PB0);  // apaga LED
	}	
}

ISR(ADC_vect){
	Valor_ADC = ADCH;			// Lectura, Justificación Izquierda
	
	// Convertir a dos dígitos hexadecimales
	uint8_t nible_alto = (Valor_ADC>>4) & 0x0F;
	uint8_t nible_bajo = Valor_ADC & 0x0F;
	
	patron_decenas = SEGMENTOS[nible_alto];
	patron_unidades = SEGMENTOS[nible_bajo];
	
	ADCSRA |= (1 << ADSC);		// Comenzar siguiente conversión
}




