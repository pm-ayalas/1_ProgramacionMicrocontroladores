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

// Variables globales (volátiles - se modifican en ISR)
volatile uint8_t CONTADOR_LEDs = 0;
volatile uint8_t BANDERA_BTN_incremento = 0;
volatile uint8_t BANDERA_BTN_decremento = 0;

// Variables para estado anterior de los botones (1=no presionado)
volatile uint8_t prev_PC0 = 1;  
volatile uint8_t prev_PC1 = 1;

/****************************************/
// Function prototypes
void setup(void);
void init_PinChange(void);
void actualizar_leds(uint8_t x);

/****************************************/
// Main Function
int main(void)
{
	cli();
	setup();
	init_PinChange();
	sei();
	
	actualizar_leds(CONTADOR_LEDs);
	
	while (1){
		
		// Verificar banderas btns
		if (BANDERA_BTN_incremento){
			BANDERA_BTN_incremento = 0;	// restablecer
			CONTADOR_LEDs++;
			actualizar_leds(CONTADOR_LEDs);
		}
		if (BANDERA_BTN_decremento){
			BANDERA_BTN_decremento = 0;	// restablecer
			CONTADOR_LEDs--;
			actualizar_leds(CONTADOR_LEDs);
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
	DDRB	|= (1 << PINB1) | (1 << PINB2) | (1 << PINB3);
	PORTB	= 3;

	// PC0,PC1 -> Entrada [Botones] pull-up - [Potenciometro]
	DDRC	&= ~((1 << PINC0) | (1 << PINC1) | (1 << PINC2));
	PORTC	|= (1 << PINC0) | (1 << PINC1);
}
void init_PinChange(void){
	// Habilitar interrupciones para PCINT1 (PORTC)
	PCICR |= (1 << PCIE1);
	// PC0 (PCINT8) - PC1 (PCINT9)
	PCMSK1 |= (1 << PCINT8) | (1 << PCINT9);
}
void actualizar_leds(uint8_t x){
	PORTD = ~x;
}

/****************************************/
// Interrupt routines

ISR(PCINT1_vect){
	// Leer PORTC
	uint8_t estado_actual = PINC;
	
	// 1. Selección de pin específico y máscara
	uint8_t actual_PC0 = (estado_actual >> PC0) & 1;
	
	if ((prev_PC0 == 1) && (actual_PC0 == 0)){
		BANDERA_BTN_decremento = 1;
	}
	prev_PC0 = actual_PC0; // Actualizar estado
	
	// 2. Selección de pin específico y máscara
	uint8_t actual_PC1 = (estado_actual >> PC1) & 1;
	
	if ((prev_PC1 == 1) && (actual_PC1 == 0)){
		BANDERA_BTN_incremento = 1;
	}
	prev_PC1 = actual_PC1; // Actualizar estado
	
}




