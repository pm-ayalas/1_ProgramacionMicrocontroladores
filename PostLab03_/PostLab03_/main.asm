/****************************************/
/*
* PostLab03_.asm
*
* Creado: 2/21/2026 1:27:31 PM
* Autor : Paula Ayala
* Descripción:	Contador binario de 4 bits con incremento
*				y decremento mediante botones con 
*				interrupciones on-change y pull-us internos.
*				Contador hexadecimal de unidades y decenas, 
*				utiliza interrupciones del TIMER0 de 10ms,
*				cambia combinación de segmentos del display 
*				cada 1 segundo. Ambos contadores funcionan
*				al mismo tiempo.		
*/

/****************************************/
// Encabezado 
/****************************************/

// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"     // Include definitions specific to ATMega328P

// ====================== //
// DATOS EN SRAM
// ====================== //
.dseg
.org    SRAM_START

C_LEDS:				.BYTE 1				// Contador LEDs

C_Display1:			.BYTE 1				// Contador Display unidades
C_Display2:			.BYTE 1				// Contador Display decenas

Display_Actual:		.BYTE 1				// Variable para ubicar el display mostrado

C_Segundos:			.BYTE 1				// Contador para las 100 interrupciones
BTN_inc:			.BYTE 1				// Bandera btn incremento
BTN_dec:			.BYTE 1				// Bandera btn decremento

// ====================== //
// FALSH
// ====================== //
.cseg
.org 0x0000

// ====================== //
// VECTOR INTERRUPCIONES
// ====================== //
JMP		PILA
.ORG	0x0008					// Dirección vector PCINT1
JMP		BTN_ISR
.ORG	0x001C					// Dirección OC0Aaddr	
JMP		TIM0_ISR			

 /****************************************/
// Configuración de la pila
PILA:
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

	// PuertoD salida para Display
	LDI		R16, 0b01111111
	OUT		DDRD, R16
	// Display inicia apagado
	LDI		R16, 0b01111111
	OUT		PORTD, R16
	LDI		R16, 0x00
	STS		C_Display1, R16		// valor inicial 00
	CALL	Mostrar_Display

	// Pines para Multiplexar Displays
	// PuertoC entrada para botones
	LDI		R16, 0b00001100
	OUT		DDRC, R16
	// pull-up habilitado para botones
	// display izquierdo activo
	LDI		R16, 0b00001011
	OUT		PORTC, R16

	// CONFIG. INTERRUPCIONES PIN-CHANGE ====== //

	// Habilitar interrupciones
	LDI		R16, (1 << PCIE1)					// 0b00000010
	STS		PCICR, R16

	// Habilitamos pines específicos
	LDI		R16, (1 << PCINT8) | (1 << PCINT9)	// PC0-PC1 - 0b00000011
	STS		PCMSK1, R16

	// INICIALIZAR TIMER0 ====== //
	CALL	IN_TIMER0

	// INICIALIZAR VARIABLES ====== //
	LDI		R16, 0x00
	STS		C_LEDs, R16
	STS		C_Segundos, R16
	STS		BTN_inc, R16
	STS		BTN_dec, R16

	LDI		R16, 0
	STS		Display_Actual, R16
	
	// habilitar interrupciones
	SEI

/****************************************/
// Loop Infinito
MAIN_LOOP:
	
	//Mostrar display correspondiente
	LDS		R16, Display_Actual
	CPI		R16, 1
	BREQ	UNIDADES

	SBI		PORTC, PC2
	CBI		PORTC, PC3
	RJMP	FIN_SELECTOR

UNIDADES:
	SBI		PORTC, PC3
	CBI		PORTC, PC2

FIN_SELECTOR:
	CALL	Mostrar_Display

	// Contador de 1 seg
	LDS		R16, C_Segundos
	CPI		R16, 100
	BRNE	LECTURA_BTNS					// No ha llegado a 1s, entonces leemos banderas btns
	
	LDI		R16, 0x00
	STS		C_Segundos, R16					// Reiniciamos contador segundos

// ==================================== //
// LOGICA CONTEO DE SEGUNDOS
// ==================================== //

	// Incremento Display
	LDS		R16, C_Display1
	LDS		R17, C_Display2

	INC		R16								// incremento contador

	CPI		R16, 10							// unidades llegó a 10?
	BRNE	CONTINUAR

	LDI		R16, 0							// reiniciamos display1					
	INC		R17								// incrementamos display2

	CPI		R17, 6							// decenas llegó a 10?
	BRNE	CONTINUAR

	LDI		R17, 0							// reiniciamos display2

CONTINUAR:

	STS		C_Display1, R16					// actualizar contadores de displays
	STS		C_Display2, R17
	
	CALL	Mostrar_Display					// mostrar valores en proto

// ==================================== //

LECTURA_BTNS:
	// Revisar BTN incremento
	LDS		R16, BTN_inc					// Cargar bandera de incremento
	CPI		R16, 1
	BRNE	LECTURA_DEC

	LDS		R16, C_LEDs						// Cargar valor actual de LEDs
	INC		R16								// incremento
	ANDI	R16, 0b00001111					// Mantener margen
	STS		C_LEDs, R16						// Guardar nuevo valor
	OUT		PORTB, R16						// Evniar a LEDs

	// Limpiar bandera incremento
	LDI		R16, 0x00
	STS		BTN_inc, R16

LECTURA_DEC:
	// Revisar BTN decremento
	LDS		R16, BTN_dec					// Cargar bandera de decremento
	CPI		R16, 1
	BRNE	MAIN_LOOP

	LDS		R16, C_LEDs						// Cargar valor actual de LEDs
	DEC		R16								// incremento
	ANDI	R16, 0b00001111					// Mantener margen
	STS		C_LEDs, R16						// Guardar nuevo valor
	OUT		PORTB, R16						// Evniar a LEDs

	// Limpiar bandera incremento
	LDI		R16, 0x00
	STS		BTN_dec, R16

    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

IN_TIMER0:
	// Modo CTC (Clear Timer on Compare Match)
	LDI		R16, (1 << WGM01)
	OUT		TCCR0A, R16

	// Prescaler 64
	LDI		R16, (0 << CS02) | (1 << CS01) | (1 << CS00)  
	OUT		TCCR0B, R16
	
	LDI		R16, 156							// R: 156.25
	OUT		OCR0A, R16

	// habilitar interrupciones por comparacion
	LDI		R16, (1 << OCIE0A)
	STS		TIMSK0, R16
	
	// Iniciar contador en 0
	LDI		R16, 0x00
	OUT		TCNT0, R16

	RET

Mostrar_Display:
	PUSH	R16
	PUSH	R17
	PUSH	ZL
	PUSH	ZH

	LDS		R20, Display_Actual

	// VERIFICAR DISPLAU CORRESPONDIENTE

	CPI		R20, 0
	BREQ	MOSTRAR_UNIDADES

	LDS		R16, C_Display2
	RJMP	FIN_SELECTORR

MOSTRAR_UNIDADES:
	LDS		R16, C_Display1

FIN_SELECTORR:

	// Apuntar a tabla de segmentos según C_Display
	LSL		R16		// mult por 2 porque dw ocupa 2 bytes
	LDI		ZL, LOW(VECTOR*2)
	LDI		ZH, HIGH(VECTOR*2)
	CLR		R17					
	ADD		ZL, R16				
	ADC		ZH, R17				// Add with Carry
	LPM		R16, Z

	OUT		PORTD, R16			// mostrar en leds

	POP		ZH
	POP		ZL
	POP		R17
	POP		R16
	RET

/****************************************/
// Interrupt routines

TIM0_ISR:

	PUSH	R16
	PUSH	R17
	IN		R16, SREG
	PUSH	R16

	// incrementar contador 100ms
	LDS		R16, C_Segundos
	INC		R16
	STS		C_Segundos, R16

	// modificar Display actual 
	// XOR (Exclusive OR) || 1 Diferentes, 0 Iguales
	LDS		R16, Display_Actual
	LDI		R17, 1
	EOR		R16, R17
	STS		Display_Actual, R16

	POP		R16
	OUT		SREG, R16
	POP		R17
	POP		R16

	RETI


BTN_ISR:

	// Guardar en pila
	PUSH	R16								
	PUSH	R17	
	IN		R16, SREG						// Guardar Status Register
	PUSH	R16	
	
	IN		R17, PINC						// Lectura btns
	SBRS	R17, PC0						// PC0=1 no presionado || PC0=0 si presionado
	RJMP	INCREMENTAR
	RJMP	REVISAR_DEC
	
INCREMENTAR:
	LDI		R16, 1
	STS		BTN_inc, R16					// Modificar estado bandera					

REVISAR_DEC:
	SBRS	R17, PC1						// PC0=1 no presionado || PC0=0 si presionado
	RJMP	DECREMENTAR
	RJMP	FIN1_ISR

DECREMENTAR:
	LDI		R16, 1
	STS		BTN_dec, R16					// Modificar estado bandera					

FIN1_ISR:
	POP		R16
	OUT		SREG, R16						// Restaurar Status Register
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
//    .dw 0x01    // A
//    .dw 0x18    // b
//    .dw 0x4A    // C
//    .dw 0x30    // d
//    .dw 0x0A    // E
//    .dw 0x0B    // F