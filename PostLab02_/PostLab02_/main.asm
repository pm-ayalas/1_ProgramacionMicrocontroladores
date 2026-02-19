/*
* PostLab02_.asm
*
* Creado: 2/18/2026 7:52:35 AM
* Autor : Paula Ayala
* Descripción:	Contador binario de 4 bits con incrementos
*				cada 1s utilizando Timer0 en modo CTC.
*				Adicional un contador hexadecimal de 4 bits
*				en 7 segmentos en el que cada incremento y
*				decremento se ejecutará mediante botones con
*				anti-rebote. 
*/

/****************************************/
// Encabezado 
/****************************************/
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P

// ====================== //
// DATOS EN SRAM
// ====================== //
.dseg
.org    SRAM_START

C_Display:		.BYTE 1				// Contador1 - Display
C_LEDs:			.BYTE 1				// Contador2 - LEDs
C_segundos:		.BYTE 1				// contador para las 10 interrupciones

BTN_inc:		.BYTE 1				
BTN_dec:		.BYTE 1
BTN_inc_uE:		.BYTE 1				// Último estado leido
BTN_dec_uE:		.BYTE 1				// Último estado leido

// ====================== //
// FALSH
// ====================== //
.cseg
.org 0x0000

// ====================== //
// VECTOR INTERRUPCIONES
// ====================== //

JMP		PILA						
.ORG	0X0008					
JMP		BTN1_ISR	 							
.ORG	0x001C
JMP		TIM0_COMP

/****************************************/
PILA:
	// Configuración de la pila
	LDI     R16, LOW(RAMEND)
	OUT     SPL, R16
	LDI     R16, HIGH(RAMEND)
	OUT     SPH, R16

/****************************************/
// Configuracion MCU
SETUP:

	// Configurar Prescaler "Principal"
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16				// Habilitar cambio de PRESCALER
	LDI		R16, 0b00000100
	STS		CLKPR, R16				// Configurar Prescaler a 16 F_cpu = 1MHz

	// Deshabilitar serial (esto apaga los demás LEDs del Arduino)
	LDI		R16, 0x00
	STS		UCSR0B, R16

	// CONFIGURACIÓN PUERTOS ====== //

	// PuertoB salida para LEDs 
	LDI		R16, 0b00001111
	OUT		DDRB, R16
	// LEDs comienzan apagados
	LDI		R16, 0b00000000
	OUT		PORTB, R16

	// PuertoD salida para Display y alarma
	LDI		R16, 0b11111111
	OUT		DDRD, R16
	// Display inicia apagado, alarma apagada
	LDI		R16, 0b01111111
	OUT		PORTD, R16
	LDI		R16, 0x09
	STS		C_Display, R16		// valor inicial 09
	CALL	Mostrar_Display

	// PuertoC entrada para botones
	LDI		R16, 0b00000000
	OUT		DDRC, R16
	// pull-up habilitado
	LDI		R16, 0b00000011
	OUT		PORTC, R16

	// CONFIG. INTERRUPCIONES PIN-CHANGE ====== //

	// Habilitar interrupción
	LDI		R16, (1 << PCIE1)
	STS		PCICR, R16
	// Habilitar pines específicos
	LDI		R16, (1 << PCINT8) | (1 << PCINT9)	// PC0-PC1
	STS		PCMSK1, R16

	// INICIALIZAR TIMER0 ====== //
	CALL	IN_TIMER0

	// INICIALIZAR VARIABLES ====== //
	LDI		R16, 0x00
	STS		C_LEDs, R16
	STS		C_segundos, R16
	STS		BTN_inc, R16
	STS		BTN_dec, R16

	// Estado inicial de btns
	LDI		R16, 0b00000001
	STS		BTN_inc_uE, R16
	LDI		R16, 0b00000010
	STS		BTN_dec_uE, R16

	// alarma apagada
	LDI		R20, 0b01111111

	// habilitar interrupciones
	SEI	
    
/****************************************/
// Loop Infinito
MAIN_LOOP:
	
	// Contador de 1 seg
	LDS		R16, C_segundos
	CPI		R16, 10
	BRNE	LECTURA_BTNS			// no ha llegado, leemos btns

	LDI		R16, 0x00
	STS		C_segundos, R16			// reiniciamos contador segundos

	// Incremento LEDs
	LDS		R16, C_LEDs
	INC		R16
	ANDI	R16, 0b00001111			// mantenemos margen
	STS		C_LEDs, R16
	OUT		PORTB, R16				// mguardamos cambios

LECTURA_BTNS:
	
	// BTN incremento
	LDS		R16, BTN_inc
	CPI		R16, 1
	BRNE	LECTURA_BTN_DEC

	// Incremento Display
	LDS		R16, C_Display
	INC		R16
	ANDI	R16, 0b00001111			// mantener marge
	STS		C_Display, R16
	CALL	Mostrar_Display			// mostrar leds

	// Limpiar bandera
	LDI		R16, 0x00
	STS		BTN_inc, R16

LECTURA_BTN_DEC:
	
	LDS		R16, BTN_dec
	CPI		R16, 1
	BRNE	REVISAR_ALARMA			

	// Decremento Display
	LDS		R16, C_Display
	DEC		R16
	ANDI	R16, 0b00001111
	STS		C_Display, R16
	CALL	Mostrar_Display

	// Limpiar bandera
	LDI		R16, 0x00
	STS		BTN_dec, R16

REVISAR_ALARMA:

	LDS		R16, C_LEDs
	LDS		R17, C_Display
	CPSE	R16, R17				// comparar contadores
	RJMP	MAIN_LOOP

	// CONTADORES IGUALES

	LDI		R16, 0x00
	STS		C_LEDs, R16
	STS		C_segundos, R16
	OUT		PORTB, R16				// reiniciar leds

	// ALARMA
	LDI		R16, 0b11111111
	CPSE	R20, R16				// compara, y salta si son iguales
	RJMP	Registro_FF

	LDI		R20, 0b01111111
	RJMP	Actualizar

Registro_FF:
	LDI		R20, 0b11111111

Actualizar:
	
	CALL	Mostrar_Display
	RJMP	MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines
IN_TIMER0:

	// Modo CTC (Clear Timer on Compare Match)
	LDI		R16, (1 << WGM01)
	OUT		TCCR0A, R16

	// Prescaler 1024
	LDI		R16, (1 << CS02) | (0 << CS01) | (1 << CS00)  
	OUT		TCCR0B, R16
	
	LDI		R16, 97
	OUT		OCR0A, R16

	// habilitar interrupciones por comparacion
	LDI		R16, (1 << OCIE0A)
	STS		TIMSK0, R16
	
	// Iniciar contador en 0
	LDI		R16, 0x00
	OUT		TCNT0, R16

	RET

MOSTRAR_DISPLAY:

	PUSH	R16
	PUSH	R17
	PUSH	ZL
	PUSH	ZH

	LDS		R16, C_Display

	// apuntar a tabla de segmentos según C_Display
	LSL		R16		// mult por 2 porque dw ocupa 2 bytes
	LDI		ZL, LOW(VECTOR*2)
	LDI		ZH, HIGH(VECTOR*2)
	CLR		R17					
	ADD		ZL, R16				
	ADC		ZH, R17
	LPM		R16, Z

	// logica alarma ****

	LDI		R18, 0b01111111
	CPSE	R20, R18
	RJMP	Alarma_encendida

	ANDI	R16, 0b01111111
	RJMP	FIN_LOGICA_ALARMA

Alarma_encendida:
	ORI		R16, 0b10000000


	// *** //

FIN_LOGICA_ALARMA:

	OUT		PORTD, R16			// mostrar en leds

	POP		ZH
	POP		ZL
	POP		R17
	POP		R16
	RET

/****************************************/
// Interrupt routines

TIM0_COMP:
	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	// incrementar contador 100ms
	LDS		R16, C_segundos
	INC		R16
	STS		C_segundos, R16

	POP		R16
	OUT		SREG, R16
	POP		R16

	RETI

BTN1_ISR:
	
	PUSH	R16
	PUSH	R17
	IN		R16, SREG
	PUSH	R16
	
	// lectura btns - estado actual
	IN		R17, PINC
	
	// Verificar PC0
	SBRS	R17, PC0
	LDI		R16, 1
	STS		BTN_inc, R16	// btn=0 entonces presionado=bandera

	// Verificar PC1
	SBRS	R17, PC1
	LDI		R16, 1
	STS		BTN_dec, R16	// btn=0 entonces presionado=bandera
	
	POP		R16
	OUT		SREG, R16
	POP		R17
	POP		R16
	
	RETI

/****************************************/

// TABLA DE PATRONES PARA DISPLAY 7 SEGMENTOS
VECTOR:
    .dw 0x40    // 0  
    .dw 0x75    // 1
    .dw 0x22    // 2
    .dw 0x24    // 3
    .dw 0x15    // 4
    .dw 0x0C    // 5
    .dw 0x08    // 6
    .dw 0x65    // 7
    .dw 0x00    // 8
    .dw 0x05    // 9
    .dw 0x01    // A
    .dw 0x18    // b
    .dw 0x4A    // C
    .dw 0x30    // d
    .dw 0x0A    // E
    .dw 0x0B    // F