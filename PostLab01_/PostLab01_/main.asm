/*
* PostLab01_.asm
*
* Creado: 2/10/2026 9:13:16 PM
* Autor : Paula Ayala - 23433
* Descripción:	Contadores binarios de 4 bits controlados por
*				botones de incremento y decremento. Incluye
*				función de sumar ambos contadores y un led
*				para indicar carry de suma.
*/
/****************************************/
// Encabezado 
.include "M328PDEF.inc"			// Include definitions specific to ATMega328P
.dseg
.org    SRAM_START

.cseg
.org 0x0000

 /****************************************/
// Configuración de la pila
LDI     R16, LOW(RAMEND)
OUT     SPL, R16
LDI     R16, HIGH(RAMEND)
OUT     SPH, R16

/****************************************/
// Configuracion MCU
SETUP:

	// Deshabilitar USART
	LDI		R16, 0x00
    STS		UCSR0B, R16 

	// PuertoD => salidas LEDs
	LDI		R16, 0b11111111			
	OUT		DDRD, R16			// PD0-PD3 => salidas

	// Iniciar con LEDs apagados
	LDI		R16, 0b00000000
	OUT		PORTD, R16	

	// PuertoB => salidas LEDs Suma
	LDI		R16, 0b00011111			
	OUT		DDRB, R16			// PD0-PD3 => salidas

	// Iniciar con LEDs apagados
	LDI		R16, 0b00000000
	OUT		PORTB, R16	

	// PuertoC => entradas BTNs
	LDI		R16, 0b00000000		
	OUT		DDRC, R16			// PD0-PD3 => entradas

	// Activar PULL-UP interno
	LDI		R16, 0b00011111
	OUT		PORTC, R16

	// Iniciar contadores en 0
	LDI		R20, 0b0000
	LDI		R21, 0b0000


    
/****************************************/
// Loop Infinito
MAIN_LOOP:

// Lectura estado BTN INCREMENTO1
LEC_BTN11:	
	IN		R16, PINC
	ANDI	R16,0b00000001
	BREQ	BTN11_PRESIONADO
	RJMP	INCNT1				// no presionado, saltar

BTN11_PRESIONADO:
	// btn si presionado
	LDI		R17, 0xFF			// 255
	CALL	TIEMPO1_

	// Leer nuevamente
	IN		R16, PINC
	ANDI	R16,0b00000001
	BRNE	INCNT1
	
	// incrementar contador
	INC		R20	
	ANDI	R20, 0x0F			// mantener 4bits
	MOV		R16, R20
	SWAP	R16					// desplazar bits
	OR		R16, R21			// mantener contenido de contador2
	OUT		PORTD, R16			// mostrar en LEDs

	// Verificar que soltaron BTN11
ESPERAR11:	
	IN		R16, PINC
	ANDI	R16, 0b00000001
	BREQ	ESPERAR11			// sigue en 0

	// esperar
	LDI		R17, 0xFF			// 255
	CALL	TIEMPO1_

INCNT1:

	// verificar btn decrementar está presioando

LEC_BTN12:
	IN		R16, PINC
	ANDI	R16,0b00000010
	BRNE	DECNT1				// no presionado, saltar

	// btn si presionado
	LDI		R17, 0xFF			// 255
	CALL	TIEMPO1_

	// Leer nuevamente
	IN		R16, PINC
	ANDI	R16,0b00000010
	BRNE	DECNT1
	
	// decrementar contador
	CPI		R20, 0				// contador en 0 ?
	BRNE	DECREMENTAR1
	LDI		R20, 0b1111			// si se encontraba en 0, asignar 15
	RJMP	MOSTRAR_DEC1

DECREMENTAR1:
	DEC		R20	

MOSTRAR_DEC1:
	MOV		R16, R20
	SWAP	R16					// desplazar bits
	OR		R16, R21			// mantener contenido de contador2
	OUT		PORTD, R16			// mostrar en LEDs

	// Verificar que soltaron BTN12
ESPERAR12:	
	IN		R16, PINC
	ANDI	R16, 0b00000010
	BREQ	ESPERAR12			// sigue en 0

	// esperar
	LDI		R17, 0xFF			// 255
	CALL	TIEMPO1_

DECNT1:

// ############################################################################# //

// Lectura estado BTN INCREMENTO2
LEC_BTN21:	
	IN		R16, PINC
	ANDI	R16,0b00000100
	BREQ	BTN21_PRESIONADO
	RJMP	INCNT2				// no presionado, saltar

BTN21_PRESIONADO:
	// btn si presionado
	LDI		R17, 0xFF			// 255
	CALL	TIEMPO1_

	// Leer nuevamente
	IN		R16, PINC
	ANDI	R16,0b00000100
	BRNE	INCNT2
	
	// incrementar contador
	INC		R21	
	ANDI	R21, 0x0F			// mantener 4bits
	MOV		R16, R20			// mantener contenido de contador1
	SWAP	R16					// desplazar bits
	OR		R16, R21			// fusionar
	OUT		PORTD, R16			// mostrar en LEDs

	// Verificar que soltaron BTN11
ESPERAR21:	
	IN		R16, PINC
	ANDI	R16, 0b00000100
	BREQ	ESPERAR21			// sigue en 0

	// esperar
	LDI		R17, 0xFF			// 255
	CALL	TIEMPO1_

INCNT2:

	// verificar btn decrementar está presioando

LEC_BTN22:
	IN		R16, PINC
	ANDI	R16,0b00001000
	BRNE	DECNT2				// no presionado, saltar

	// btn si presionado
	LDI		R17, 0xFF			// 255
	CALL	TIEMPO1_

	// Leer nuevamente
	IN		R16, PINC
	ANDI	R16,0b00001000
	BRNE	DECNT2
	
	// decrementar contador
	CPI		R21, 0				// contador en 0 ?
	BRNE	DECREMENTAR2
	LDI		R21, 0b1111			// si se encontraba en 0, asignar 15
	RJMP	MOSTRAR_DEC2

DECREMENTAR2:
	DEC		R21	

MOSTRAR_DEC2:
	MOV		R16, R20			// mantener contenido de contador1
	SWAP	R16					// desplazar bits
	OR		R16, R21			// fusionar
	OUT		PORTD, R16			// mostrar en LEDs

	// Verificar que soltaron BTN12
ESPERAR22:	
	IN		R16, PINC
	ANDI	R16, 0b00001000
	BREQ	ESPERAR22			// sigue en 0

	// esperar
	LDI		R17, 0xFF			// 255
	CALL	TIEMPO1_

DECNT2:

// ############################################################################# //

// Lectura estado BTN SUMA
LEC_BTN_SUMA:	
	IN		R16, PINC
	ANDI	R16,0b00010000
	BREQ	BTNsuma_PRESIONADO
	RJMP	SUMNT				// no presionado, saltar

BTNsuma_PRESIONADO:
	// btn si presionado
	LDI		R17, 0xFF			// 255
	CALL	TIEMPO1_

	// Leer nuevamente
	IN		R16, PINC
	ANDI	R16,0b00010000
	BRNE	SUMNT
	
	// Suma de contadores
	MOV		R16, R20			// copiamos R20
	ADD		R16, R21			// resultado de summa en R16
	
	MOV		R22, R16			// copiamos resultado de suma
	ANDI	R22, 0b00010000		// mascara para ver carry
	SWAP	R22

	ANDI	R16, 0x0F			// mantener 4 bits
	OUT		PORTB, R16			// mostrar en LEDs el resultado

	CPI		R22, 0b0001			// verificamos carry
	BREQ	CARRY

	RJMP	yap					// si ni hay carry, finalizamos

CARRY: 
	SBI		PORTB, 5

yap:

SUMNT:

    RJMP    MAIN_LOOP

/****************************************/
// NON-Interrupt subroutines

TIEMPO1_:
	DEC		R17
	BRNE	TIEMPO1_
	LDI		R17, 0XFF
	CALL	TIEMPO2_
	RET

TIEMPO2_:
	DEC		R17
	BRNE	TIEMPO2_
	LDI		R17, 0XFF
	CALL	TIEMPO3_
	RET

TIEMPO3_:
	DEC		R17
	BRNE	TIEMPO3_
	LDI		R17, 0XFF
	CALL	TIEMPO4_
	RET

TIEMPO4_:
	DEC		R17
	BRNE	TIEMPO4_
	LDI		R17, 0XFF
	CALL	TIEMPO5_
	RET

TIEMPO5_:
	DEC		R17
	BRNE	TIEMPO5_
	LDI		R17, 0XFF
	CALL	TIEMPO6_
	RET

TIEMPO6_:
	DEC		R17
	BRNE	TIEMPO6_
	RET
	
/****************************************/
// Interrupt routines

/****************************************/







