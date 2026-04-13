/****************************************/
/*
* Proyecto1_.asm
*
* Creado: 2/27/2026 4:54:20 PM
* Autor : Paula Ayala
* Descripción:	
*/

/*******************************************************************************************************/
// ENCABEZADO 

// Encabezado (Definición de Registros, Variables y Constantes)
.include "M328PDEF.inc"							// Include definitions specific to ATMega328P

// ================================ //
// DATOS EN SRAM
// ================================ //
.dseg
.org    SRAM_START

SEG_UNIDAD:				.BYTE 1					// Valores Segundos
SEG_DECENA:				.BYTE 1
MIN_UNIDAD:				.BYTE 1					// Valores Minutos
MIN_DECENA:				.BYTE 1
HRS_UNIDAD:				.BYTE 1					// Valores Horas
HRS_DECENA:				.BYTE 1		
DIA_UNIDAD:				.BYTE 1					// Valores Días
DIA_DECENA:				.BYTE 1
MES_UNIDAD:				.BYTE 1					// Valores Mes
MES_DECENA:				.BYTE 1
ANIO:					.BYTE 1					// Valor Año	

TEMP_MIN_UNIDAD:		.BYTE 1					// Valores para configuración MODO 4
TEMP_MIN_DECENA:		.BYTE 1
TEMP_HRS_UNIDAD:		.BYTE 1					// Valores para configuración MODO 5
TEMP_HRS_DECENA:		.BYTE 1
TEMP_MES_UNIDAD:		.BYTE 1					// Valores para configuración MODO 6
TEMP_MES_DECENA:		.BYTE 1
TEMP_DIA_UNIDAD:		.BYTE 1					// Valores para configuración MODO 7
TEMP_DIA_DECENA:		.BYTE 1

ALARMA_MIN_UNIDAD:		.BYTE 1					// Valores Minutos para configuración ALARMA
ALARMA_MIN_DECENA:		.BYTE 1
ALARMA_HRS_UNIDAD:		.BYTE 1					// Valores Horas para configuración ALARMA
ALARMA_HRS_DECENA:		.BYTE 1		

DISPLAY_ACTUAL:			.BYTE 1					// Variable para ubicar el display mostrado
MODO:					.BYTE 1					// Modo actual - define lo que se mostrará 

ALARMA:					.BYTE 1					// Estado de la alarma y valores
ALARMA_MIN:				.BYTE 1
ALARMA_HRS:				.BYTE 1

C_SEGUNDOS:				.BYTE 1					// Contador para las 100 interrupciones (llegar a 1seg)
PUNTITOS:				.BYTE 1					// Variable para estado PUNTITOS

BTN_INC:				.BYTE 1					// Bandera btn incremento
BTN_DEC:				.BYTE 1					// Bandera btn decremento

GUARDAR_VALORES:		.BYTE 1					// Bandera para guardar nuevos valores en Modo Configuración
	
// ================================ //
// FALSH
// ================================ //
.cseg
.org 0x0000

// ================================ //
// VECTOR INTERRUPCIONES
// ================================ //
JMP		PILA

.ORG	0x0008									// Dirección vector PCINT1
JMP		BTN_ISR
.ORG	0x001C									// Dirección OC0Aaddr	
JMP		TIM0_ISR			

/*******************************************************************************************************/
// Configuración de la pila
PILA:
	LDI     R16, LOW(RAMEND)
	OUT     SPL, R16
	LDI     R16, HIGH(RAMEND)
	OUT     SPH, R16

/*******************************************************************************************************/
// Configuracion MCU
SETUP:

	// Prescaler principal
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16							// Habilitar cambio de PRESCALER
	LDI		R16, 0b00000100
	STS		CLKPR, R16							// Configurar Prescaler a 16 F_cpu = 1MHz

	// Deshabilitar serial (RX, TX)
	LDI		R16, 0x00
	STS		UCSR0B, R16

	// ================================ //
	// CONFIGURACIÓN PUERTOS
	// ================================ //

	// PuertoB => Multiplexación PB0-PB3 || ALARMA PB4 || LED Config PB5
	LDI		R16, 0b00111111
	OUT		DDRB, R16
	LDI		R16, 0b00000000						// Inicia Apagado
	OUT		PORTB, R16

	// PuertoD => Displays PD0-PD6 || Puntitos PD7
	LDI		R16, 0b11111111
	OUT		DDRD, R16
	LDI		R16, 0b01111111						// Inicia Apagado
	OUT		PORTD, R16

	// PuertoC => Botones PC0-PC3 || LEDs Estados PV4-PC5
	LDI		R16, 0b00110000
	OUT		DDRC, R16
	LDI		R16, 0b00001111						// pull-up habilitado btns
	OUT		PORTC, R16

	// ================================ //
	// CONFIG INTERRUPCIONES
	// INICIALIZAR TIMER0
	// ================================ //

	// PIN-CHANGE - Habilitar interrupciones 
	LDI		R16, (1 << PCIE1)					// 0b00000010
	STS		PCICR, R16

	// Habilitamos pines específicos (btns - PC0-PC1)
	LDI		R16, (1 << PCINT8) | (1 << PCINT9)	| (1 << PCINT10) | (1 << PCINT11)
	STS		PCMSK1, R16

	// INICIALIZAR TIMER0 ====== //
	CALL	IN_TIMER0

	// VALORES INICIALES ======= //
	LDI		R16, 0x00
	STS		SEG_UNIDAD, R16
	STS		SEG_DECENA, R16
	STS		MIN_UNIDAD, R16
	STS		MIN_DECENA, R16
	STS		HRS_UNIDAD, R16
	STS		HRS_DECENA, R16

	STS		DIA_DECENA, R16
	STS		MES_DECENA, R16
	STS		ALARMA, R16

	STS		ALARMA_MIN_UNIDAD, R16
	STS		ALARMA_MIN_DECENA, R16
	STS		ALARMA_HRS_UNIDAD, R16
	STS		ALARMA_HRS_DECENA, R16

	STS		PUNTITOS, R16
	STS		C_SEGUNDOS, R16
	STS		BTN_INC, R16
	STS		BTN_DEC, R16

	STS		TEMP_MIN_UNIDAD, R16
	STS		TEMP_MIN_DECENA, R16
	STS		TEMP_HRS_UNIDAD, R16
	STS		TEMP_HRS_DECENA, R16
	STS		TEMP_MES_UNIDAD, R16
	STS		TEMP_MES_DECENA, R16
	STS		TEMP_DIA_UNIDAD, R16
	STS		TEMP_DIA_DECENA, R16

	STS		GUARDAR_VALORES, R16

	LDI		R16, 1
	STS		DIA_UNIDAD, R16
	STS		MES_UNIDAD, R16
	STS		DISPLAY_ACTUAL, R16
	STS		MODO, R16
	
	// habilitar interrupciones
	SEI
	    
/****************************************/
// Loop Infinito
MAIN_LOOP:

	// Contador 0.5 seg
	LDS		R16, C_SEGUNDOS
	CPI		R16, 100
	BRNE	VERIFICAR_1S
		
	LDS		R20, MODO							// Encender puntitos según modo
	CPI		R20, 3
	BREQ	DISPLAYSS
	CPI		R20, 6
	BREQ	DISPLAYSS
	CPI		R20, 7
	BREQ	DISPLAYSS

	SBI		PORTD, 7							// Encender puntitos
	LDI		R16, 0b10000000						// Modificar Bandera PUNTITOS
	STS		PUNTITOS, R16
	RJMP	DISPLAYSS

VERIFICAR_1S:
	// Contador 1 seg
	CPI		R16, 200
	BRNE	DISPLAYSS							// si no se ha cumplido el segundo, continuamos

	// si se ha llegado al 1S
	CBI		PORTD, 7							// Apagar puntitos
	LDI		R16, 0b00000000						// Modificar Bandera PUNTITOS
	STS		PUNTITOS, R16
	CALL	REFRESCAR_RELOJ1					// Actulizar valores de reloj
	CLR		R16
	STS		C_SEGUNDOS, R16						// Limpiar contador Segundos

DISPLAYSS:
	// Mostrar valores en display correspondiente
	// (Mandar señal a transistor según display)
	CALL	DISPLAY_CORRESPONDIENTE

	// Mostrar en protoboard según modo
	LDS		R16, MODO
	
	CPI		R16, 1
	BRNE	REVISAR_M2
	SBI		PORTC, 4	//	
	CBI		PORTC, 5	//
	CBI		PORTB, 5	//
	CALL	MOSTRAR_MODO1
	RJMP	MAIN_LOOP1

REVISAR_M2:
	CPI		R16, 2
	BRNE	REVISAR_M3
	SBI		PORTC, 4	//
	CBI		PORTC, 5	//
	CBI		PORTB, 5	//
	CALL	MOSTRAR_MODO2
	RJMP	MAIN_LOOP1
REVISAR_M3:
	CPI		R16, 3
	BRNE	REVISAR_M4
	CBI		PORTC, 4	//
	SBI		PORTC, 5	//
	CBI		PORTB, 5	//
	CALL	MOSTRAR_MODO3
	RJMP	MAIN_LOOP1
REVISAR_M4:
	CPI		R16, 4
	BRNE	REVISAR_M5
	SBI		PORTC, 4	//
	CBI		PORTC, 5	//
	SBI		PORTB, 5	//
	CALL	MOSTRAR_MODO4
	RJMP	MAIN_LOOP1
REVISAR_M5:
	CPI		R16, 5
	BRNE	REVISAR_M6
	SBI		PORTC, 4	//
	CBI		PORTC, 5	//
	SBI		PORTB, 5	//
	CALL	MOSTRAR_MODO5
	RJMP	MAIN_LOOP1
REVISAR_M6:
	CPI		R16, 6
	BRNE	REVISAR_M7
	CBI		PORTC, 4	//
	SBI		PORTC, 5	//
	SBI		PORTB, 5	//
	CALL	MOSTRAR_MODO6
	RJMP	MAIN_LOOP1
REVISAR_M7:
	CPI		R16, 7
	BRNE	REVISAR_M8
	CBI		PORTC, 4	//
	SBI		PORTC, 5	//
	SBI		PORTB, 5	//
	CALL	MOSTRAR_MODO7
	RJMP	MAIN_LOOP1
REVISAR_M8:
	CPI		R16, 8
	BRNE	REVISAR_M9
	CBI		PORTC, 4	//
	CBI		PORTC, 5	//
	SBI		PORTB, 5	//
	CALL	MOSTRAR_MODO4
	RJMP	MAIN_LOOP1
REVISAR_M9:
	CPI		R16, 9
	BRNE	MAIN_LOOP1
	CBI		PORTC, 4	//
	CBI		PORTC, 5	//
	SBI		PORTB, 5	//
	CALL	MOSTRAR_MODO5

// ========================================== //
// Lógica verificar ALARMA
// ========================================== //

	LDS		R16, ALARMA_HRS_DECENA
	LDS		R17, HRS_DECENA
	CP		R16, R17
	BREQ	VERIFICAR2
	RJMP	MAIN_LOOP1

VERIFICAR2:
	LDS		R16, ALARMA_HRS_UNIDAD
	LDS		R17, HRS_UNIDAD
	CP		R16, R17
	BREQ	VERIFICAR3
	RJMP	MAIN_LOOP1

VERIFICAR3:
	LDS		R16, ALARMA_MIN_DECENA
	LDS		R17, MIN_DECENA
	CP		R16, R17
	BREQ	VERIFICAR4
	RJMP	MAIN_LOOP1

VERIFICAR4:
	LDS		R16, ALARMA_MIN_UNIDAD
	LDS		R17, MIN_UNIDAD
	CP		R16, R17
	BREQ	ENCENDER_ALARMA
	RJMP	MAIN_LOOP1

ENCENDER_ALARMA:

MAIN_LOOP1:
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
	
	// Valor para 5ms
	LDI		R16, 78							// R: 78
	OUT		OCR0A, R16

	// habilitar interrupciones por comparacion
	LDI		R16, (1 << OCIE0A)
	STS		TIMSK0, R16
	
	// Iniciar contador en 0
	LDI		R16, 0x00
	OUT		TCNT0, R16

	RET

DISPLAY_CORRESPONDIENTE:

	LDS		R16, DISPLAY_ACTUAL
	CPI		R16, 1
	BREQ	UNIDADES1

	CPI		R16, 2
	BREQ	DECENAS1

	CPI		R16, 3
	BREQ	UNIDADES2

	// sino, el display actual es DECENAS2
	CBI		PORTB, 0
	CBI		PORTB, 1
	CBI		PORTB, 2
	SBI		PORTB, 3
	RJMP	FIN_DISPLAY_CORRESPONDIENTE

UNIDADES1:
	SBI		PORTB, 0
	CBI		PORTB, 1
	CBI		PORTB, 2
	CBI		PORTB, 3
	RJMP	FIN_DISPLAY_CORRESPONDIENTE

DECENAS1:
	CBI		PORTB, 0
	SBI		PORTB, 1
	CBI		PORTB, 2
	CBI		PORTB, 3
	RJMP	FIN_DISPLAY_CORRESPONDIENTE
UNIDADES2:
	CBI		PORTB, 0
	CBI		PORTB, 1
	SBI		PORTB, 2
	CBI		PORTB, 3
	RJMP	FIN_DISPLAY_CORRESPONDIENTE

FIN_DISPLAY_CORRESPONDIENTE:
	RET

// ================================ //
// MODO 1 => MIN:SEG
// ================================ //
MOSTRAR_MODO1:
	LDS		R16, DISPLAY_ACTUAL					// Enviar valor según DISPLAY ACTUAL

	CPI		R16, 1
	BREQ	M1_DISP1
	CPI		R16, 2
	BREQ	M1_DISP2
	CPI		R16, 3
	BREQ	M1_DISP3
	RJMP	M1_DISP4

M1_DISP1:
	LDS		R20, SEG_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M1_FIN

M1_DISP2:
	LDS		R20, SEG_DECENA
	CALL	ENVIAR_A_DISPLAY
	RJMP	M1_FIN

M1_DISP3:
	LDS		R20, MIN_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M1_FIN

M1_DISP4:
	LDS		R20, MIN_DECENA
	CALL	ENVIAR_A_DISPLAY

M1_FIN:
	RET

// ================================ //
// MODO 2 => HRS:MIN
// ================================ //
MOSTRAR_MODO2:
	LDS		R16, DISPLAY_ACTUAL					// Enviar valor según DISPLAY ACTUAL

	CPI		R16, 1
	BREQ	M2_DISP1
	CPI		R16, 2
	BREQ	M2_DISP2
	CPI		R16, 3
	BREQ	M2_DISP3
	RJMP	M2_DISP4

M2_DISP1:
	LDS		R20, MIN_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M2_FIN

M2_DISP2:
	LDS		R20, MIN_DECENA
	CALL	ENVIAR_A_DISPLAY
	RJMP	M2_FIN

M2_DISP3:
	LDS		R20, HRS_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M2_FIN

M2_DISP4:
	LDS		R20, HRS_UNIDAD
	CALL	ENVIAR_A_DISPLAY

M2_FIN:
	RET

// ================================ //
// MODO 3 => DIA/MES
// ================================ //
MOSTRAR_MODO3:
	LDS		R16, DISPLAY_ACTUAL					// Enviar valor según DISPLAY ACTUAL

	CPI		R16, 1
	BREQ	M3_DISP1
	CPI		R16, 2
	BREQ	M3_DISP2
	CPI		R16, 3
	BREQ	M3_DISP3
	RJMP	M3_DISP4

M3_DISP1:
	LDS		R20, MES_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M3_FIN

M3_DISP2:
	LDS		R20, MES_DECENA
	CALL	ENVIAR_A_DISPLAY
	RJMP	M3_FIN

M3_DISP3:
	LDS		R20, DIA_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M3_FIN

M3_DISP4:
	LDS		R20, DIA_DECENA
	CALL	ENVIAR_A_DISPLAY

M3_FIN:
	RET

// ================================ //
// MODO 4 => HRS:MIN [Modifica MIN] 
// ================================ //
MOSTRAR_MODO4:
	LDS		R16, DISPLAY_ACTUAL					// Enviar valor según DISPLAY ACTUAL

	CPI		R16, 1
	BREQ	M4_DISP1
	CPI		R16, 2
	BREQ	M4_DISP2
	CPI		R16, 3
	BREQ	M4_DISP3
	RJMP	M4_DISP4

	// VARIABLES TEMPORALES
M4_DISP1:
	LDS		R20, TEMP_MIN_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M4_FIN

M4_DISP2:
	LDS		R20, TEMP_MIN_DECENA
	CALL	ENVIAR_A_DISPLAY
	RJMP	M4_FIN

M4_DISP3:
	LDS		R20, HRS_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M4_FIN

M4_DISP4:
	LDS		R20, HRS_DECENA
	CALL	ENVIAR_A_DISPLAY

M4_FIN:

// VERIFICAR BANDERAS DECREMENTO-INCREMENTO
// =========================================== //

	LDS		R25, BTN_INC
	CPI		R25, 1
	BREQ	SUMA_MINUTOS	

	LDS		R25, BTN_DEC
	CPI		R25, 1
	BREQ	RESTA_MINUTOS

SUMA_MINUTOS:
	LDI		R25, 0								// Limpiar Bandera
	STS		BTN_INC, R25

	LDS		R24, TEMP_MIN_UNIDAD
	LDS		R26, TEMP_MIN_DECENA

	INC		R24
	CPI		R24, 10
	BRLT	NO_REINICIO41_UNIDAD

	LDI		R24, 0
	INC		R25
	CPI		R25, 6
	BRLT	NO_REINICIO41_DECENA

	LDI		R25, 0

NO_REINICIO41_UNIDAD:
NO_REINICIO41_DECENA:

	STS		TEMP_MIN_UNIDAD, R24
	STS		TEMP_MIN_DECENA, R25

	RJMP	M4_FIN2

RESTA_MINUTOS:
	LDI		R25, 0								// Limpiar Bandera
	STS		BTN_DEC, R25

	LDS		R24, TEMP_MIN_UNIDAD
	LDS		R26, TEMP_MIN_DECENA

	SUBI	R24, 1
	CPI		R24, 0xFF

	BRCC	NO_UNDERFLOW1

	LDI		R24, 9
	SUBI	R25, 1
	CPI		R25, 0xFF							// decenas también hicieron underflow?
	BRCC	NO_UNDERFLOW2

	LDI		R25, 5
	RJMP	M4_FIN2	

NO_UNDERFLOW1:
NO_UNDERFLOW2:

	STS		TEMP_MIN_UNIDAD, R24
	STS		TEMP_MIN_DECENA, R25

M4_FIN2:

// VERIFICAR BANDERA GUARDAR NUEVOS VALORES
// =========================================== //

	LDS		R25, GUARDAR_VALORES
	CPI		R25, 1
	BREQ	ACTUALIZAR_INFO_M4
	RJMP	M4_FIN3

ACTUALIZAR_INFO_M4:
	LDS		R25, TEMP_MIN_UNIDAD
	STS		MIN_UNIDAD, R25
	LDS		R25, TEMP_MIN_DECENA
	STS		MIN_DECENA, R25

	LDI		R25, 0								// Limpiar bandera
	STS		GUARDAR_VALORES, R25

M4_FIN3:
	RET

// ================================ //
// MODO 5 => HRS:MIN [Modifica HRS] 
// ================================ //
MOSTRAR_MODO5:
	LDS		R16, DISPLAY_ACTUAL					// Enviar valor según DISPLAY ACTUAL

	CPI		R16, 1
	BREQ	M5_DISP1
	CPI		R16, 2
	BREQ	M5_DISP2
	CPI		R16, 3
	BREQ	M5_DISP3
	RJMP	M5_DISP4

	// VARIABLES TEMPORALES
M5_DISP1:
	LDS		R20, MIN_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M4_FIN

M5_DISP2:
	LDS		R20, MIN_DECENA
	CALL	ENVIAR_A_DISPLAY
	RJMP	M4_FIN

M5_DISP3:
	LDS		R20, TEMP_HRS_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M4_FIN

M5_DISP4:
	LDS		R20, TEMP_HRS_DECENA
	CALL	ENVIAR_A_DISPLAY

M5_FIN:

// VERIFICAR BANDERAS DECREMENTO-INCREMENTO
// =========================================== //

	LDS		R25, BTN_INC
	CPI		R25, 1
	BREQ	SUMA_HORAS	

	LDS		R25, BTN_DEC
	CPI		R25, 1
	BREQ	RESTA_HORAS

SUMA_HORAS:
	LDI		R25, 0								// Limpiar Bandera
	STS		BTN_INC, R25

	LDS		R25, TEMP_HRS_UNIDAD
	INC		R25
	STS		TEMP_HRS_UNIDAD, R25
	CALL	REFRESCAR_MODO5

	RJMP	M5_FIN2

RESTA_HORAS:
	LDI		R25, 0								// Limpiar Bandera
	STS		BTN_DEC, R25

	LDS		R25, TEMP_HRS_UNIDAD
	DEC		R25
	STS		TEMP_HRS_UNIDAD, R25
	CALL	REFRESCAR_MODO5

M5_FIN2:

// VERIFICAR BANDERA GUARDAR NUEVOS VALORES
// =========================================== //

	LDS		R25, GUARDAR_VALORES
	CPI		R25, 1
	BREQ	ACTUALIZAR_INFO_M5
	RJMP	M5_FIN3

ACTUALIZAR_INFO_M5:
	LDS		R25, TEMP_HRS_UNIDAD
	STS		HRS_UNIDAD, R25
	LDS		R25, TEMP_HRS_DECENA
	STS		HRS_DECENA, R25

	LDI		R25, 0								// Limpiar bandera
	STS		GUARDAR_VALORES, R25

M5_FIN3:
	RET

// ================================ //
// MODO 6 => DIA/MES [Modifica MES]
// ================================ //
MOSTRAR_MODO6:

	LDS		R16, DISPLAY_ACTUAL					// Enviar valor según DISPLAY ACTUAL

	CPI		R16, 1
	BREQ	M6_DISP1
	CPI		R16, 2
	BREQ	M6_DISP2
	CPI		R16, 3
	BREQ	M6_DISP3
	RJMP	M6_DISP4

	// VARIABLES TEMPORALES
M6_DISP1:
	LDS		R20, TEMP_MES_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M6_FIN

M6_DISP2:
	LDS		R20, TEMP_MES_DECENA
	CALL	ENVIAR_A_DISPLAY
	RJMP	M6_FIN

M6_DISP3:
	LDS		R20, DIA_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M6_FIN

M6_DISP4:
	LDS		R20, DIA_DECENA
	CALL	ENVIAR_A_DISPLAY

M6_FIN:

// VERIFICAR BANDERAS DECREMENTO-INCREMENTO
// =========================================== //

	LDS		R25, BTN_INC
	CPI		R25, 1
	BREQ	SUMA_MESES	

	LDS		R25, BTN_DEC
	CPI		R25, 1
	BREQ	RESTA_MESES

SUMA_MESES:
	LDI		R25, 0								// Limpiar Bandera
	STS		BTN_INC, R25

	LDS		R25, TEMP_MES_UNIDAD
	INC		R25
	STS		TEMP_MES_UNIDAD, R25
	CALL	REFRESCAR_MODO6

	RJMP	M6_FIN2

RESTA_MESES:
	LDI		R25, 0								// Limpiar Bandera
	STS		BTN_DEC, R25

	LDS		R25, TEMP_MES_UNIDAD
	DEC		R25
	STS		TEMP_MES_UNIDAD, R25
	CALL	REFRESCAR_MODO6

M6_FIN2:

// VERIFICAR BANDERA GUARDAR NUEVOS VALORES
// =========================================== //

	LDS		R25, GUARDAR_VALORES
	CPI		R25, 1
	BREQ	ACTUALIZAR_INFO_M6
	RJMP	M6_FIN3

ACTUALIZAR_INFO_M6:
	LDS		R25, TEMP_MES_UNIDAD
	STS		MES_UNIDAD, R25
	LDS		R25, TEMP_MES_DECENA
	STS		MES_DECENA, R25

	LDI		R25, 0								// Limpiar bandera
	STS		GUARDAR_VALORES, R25

M6_FIN3:
	RET

// ================================ //
// MODO 7 => DIA/MES [Modifica DIAS]
// ================================ //
MOSTRAR_MODO7:

	LDS		R16, DISPLAY_ACTUAL					// Enviar valor según DISPLAY ACTUAL

	CPI		R16, 1
	BREQ	M7_DISP1
	CPI		R16, 2
	BREQ	M7_DISP2
	CPI		R16, 3
	BREQ	M7_DISP3
	RJMP	M7_DISP4

	// VARIABLES TEMPORALES
M7_DISP1:
	LDS		R20, MES_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M6_FIN

M7_DISP2:
	LDS		R20, MES_DECENA
	CALL	ENVIAR_A_DISPLAY
	RJMP	M6_FIN

M7_DISP3:
	LDS		R20, TEMP_DIA_UNIDAD
	CALL	ENVIAR_A_DISPLAY
	RJMP	M6_FIN

M7_DISP4:
	LDS		R20, TEMP_DIA_DECENA
	CALL	ENVIAR_A_DISPLAY

M7_FIN:

// VERIFICAR BANDERAS DECREMENTO-INCREMENTO
// =========================================== //

	LDS		R25, BTN_INC
	CPI		R25, 1
	BREQ	SUMA_DIAS	

	LDS		R25, BTN_DEC
	CPI		R25, 1
	BREQ	RESTA_DIAS

SUMA_DIAS:
	LDI		R25, 0								// Limpiar Bandera
	STS		BTN_INC, R25

	LDS		R25, TEMP_DIA_UNIDAD
	INC		R25
	STS		TEMP_DIA_UNIDAD, R25
	CALL	REFRESCAR_MODO7

	RJMP	M7_FIN2

RESTA_DIAS:
	LDI		R25, 0								// Limpiar Bandera
	STS		BTN_DEC, R25

	LDS		R25, TEMP_DIA_UNIDAD
	DEC		R25
	STS		TEMP_DIA_UNIDAD, R25
	CALL	REFRESCAR_MODO7

M7_FIN2:

// VERIFICAR BANDERA GUARDAR NUEVOS VALORES
// =========================================== //

	LDS		R25, GUARDAR_VALORES
	CPI		R25, 1
	BREQ	ACTUALIZAR_INFO_M7
	RJMP	M7_FIN3

ACTUALIZAR_INFO_M7:
	LDS		R25, TEMP_DIA_UNIDAD
	STS		DIA_UNIDAD, R25
	LDS		R25, TEMP_DIA_DECENA
	STS		DIA_DECENA, R25

	LDI		R25, 0								// Limpiar bandera
	STS		GUARDAR_VALORES, R25

M7_FIN3:
	RET

ENVIAR_A_DISPLAY:
	
	PUSH	ZH
	PUSH	ZL
	PUSH	R16
	PUSH	R17
    
	// Buscar configuración de segmentos en VECTOR
	LSL		R20									// mult por 2 porque dw ocupa 2 bytes
	LDI		ZH, HIGH(VECTOR*2)
	LDI		ZL, LOW(VECTOR*2)
	LDI		R16, 0
	ADD		ZL, R20
	ADC		ZH, R16								// ZH = ZH + R16 + C (sumar acarreo si hubo)
	LPM		R20, Z								// Load Program Memory (cargar según puntero)
    
	// No modificar estado de PUNTITOS
	LDS		R21, PUNTITOS
	OR		R20, R21

    // Enviar a Puerto
	OUT		PORTD, R20
    
	POP		R17
	POP		R16
	POP		ZL
	POP		ZH
	RET

REFRESCAR_RELOJ1:
	
	// ================================ //
	// SEGUNDOS UNIDADES
	// ================================ //
	LDS		R16, SEG_UNIDAD
	CPI		R16, 9
	BREQ	REINICIO1
	INC		R16
	STS		SEG_UNIDAD, R16
	RJMP	FIN_REFRESCAR_RELOJ

REINICIO1:
	LDI		R16, 0
	STS		SEG_UNIDAD, R16	

	// ================================ //
	// SEGUNDOS DECENAS
	// ================================ //
	LDS		R16, SEG_DECENA
	CPI		R16, 5
	BREQ	REINICIO2
	INC		R16
	STS		SEG_DECENA, R16
	RJMP	FIN_REFRESCAR_RELOJ

REINICIO2:
	LDI		R16, 0
	STS		SEG_DECENA, R16

	// ================================ //
	// MINUTOS UNIDADES
	// ================================ //
	LDS		R16, MIN_UNIDAD
	CPI		R16, 9
	BREQ	REINICIO3
	INC		R16
	STS		MIN_UNIDAD, R16
	RJMP	FIN_REFRESCAR_RELOJ

REINICIO3:
	LDI		R16, 0
	STS		MIN_UNIDAD, R16

	// ================================ //
	// MINUTOS DECENAS
	// ================================ //
	LDS		R16, MIN_DECENA
	CPI		R16, 6
	BREQ	REINICIO4
	INC		R16
	STS		MIN_DECENA, R16
	RJMP	FIN_REFRESCAR_RELOJ

REINICIO4:
	LDI		R16, 0
	STS		MIN_DECENA, R16

	// ================================ //
	// HORAS (COMPLETO)
	// ================================ //
	LDS		R17, HRS_UNIDAD
	LDS		R18, HRS_DECENA

	CPI		R18, 2
	BREQ	INCREMENTAR_HRS_UNIDAD

	CPI		R17, 9
	BREQ	INCREMENTAR_HRS_DECENA
	INC		R17
	STS		HRS_UNIDAD, R17
	RJMP	FIN_REFRESCAR_RELOJ

INCREMENTAR_HRS_DECENA:
	INC		R18
	LDI		R17, 0
	STS		HRS_UNIDAD, R17
	STS		HRS_DECENA, R18
	RJMP	FIN_REFRESCAR_RELOJ

INCREMENTAR_HRS_UNIDAD:
	CPI		R17, 4
	BREQ	REINICIO5
	INC		R17
	STS		HRS_UNIDAD, R17
	RJMP	FIN_REFRESCAR_RELOJ

REINICIO5:
	LDI		R17, 0
	STS		HRS_UNIDAD, R17
	STS		HRS_DECENA, R17	

	// ================================ //
	// DIAS (COMPLETO)
	// ================================ //
	LDS		R16, DIA_DECENA
	LDS		R17, DIA_UNIDAD

	// Fusionar DÍAS
	MOV		R18, R16
	LDI		R19, 10
	MUL		R18, R19
	ADD		R18, R17	

	// Obtener días correspondientes
	CALL	OBTENER_DIAS_DEL_MES				// R21 = días del mes

	// Incrementar día
	INC		R18

	CP		R18, R21
	BREQ	DIA_REINICIAR

	// Regresar FUSION a UNIDAD y DECENA
	CALL	DES_FUSIONAR						// R20 = decenas | R21 = unidades

	STS		DIA_DECENA, R20
	STS		DIA_UNIDAD, R21
	RJMP	FIN_REFRESCAR_RELOJ

DIA_REINICIAR:
	LDI		R20, 0
	STS		DIA_DECENA, R20
	LDI		R20, 1
	STS		DIA_UNIDAD, R20
	
	// Ahora incrementar MES	

	// ================================ //
	// MES (COMPLETO)
	// ================================ //
	LDS		R16, MES_DECENA
	LDS		R17, MES_UNIDAD

	// Fusionar DÍAS
	MOV		R18, R16
	LDI		R19, 10
	MUL		R18, R19
	ADD		R18, R17

	INC		R18									// Incrementar MES

	CPI		R18, 13								// mantener margen de 12 meses
	BREQ	MES_REINICIAR

	// Regresar FUSION a UNIDAD y DECENA
	CALL	DES_FUSIONAR						// R20 = decenas | R21 = unidades
	
	STS		MES_DECENA, R20
	STS		MES_UNIDAD,	R21
	RJMP	FIN_REFRESCAR_RELOJ

MES_REINICIAR:

	// Reiniciar a enero (01)
	LDI		R20, 0
	STS		MES_DECENA, R20
	LDI		R21, 1
	STS		MES_UNIDAD, R21

FIN_REFRESCAR_RELOJ:
	RET

// ############################################################################## // -- Refrescar información pero con Valores Temporales
REFRESCAR_MODO4:		// ----------------------------- MINUTOS

	// ================================ //
	// MINUTOS UNIDADES
	// ================================ //
	LDS		R16, TEMP_MIN_UNIDAD
	CPI		R16, 9
	BREQ	REINICIO32
	INC		R16
	STS		TEMP_MIN_UNIDAD, R16
	RJMP	FIN_REFRESCAR_MODO4

REINICIO32:
	LDI		R16, 0
	STS		TEMP_MIN_UNIDAD, R16

	// ================================ //
	// MINUTOS DECENAS
	// ================================ //
	LDS		R16, TEMP_MIN_DECENA
	CPI		R16, 6
	BREQ	REINICIO42
	INC		R16
	STS		TEMP_MIN_DECENA, R16
	RJMP	FIN_REFRESCAR_MODO4

REINICIO42:
	LDI		R16, 0
	STS		TEMP_MIN_DECENA, R16

FIN_REFRESCAR_MODO4:
RET

REFRESCAR_MODO5:		// ----------------------------- HRS
RET

REFRESCAR_MODO6:		// ----------------------------- MESES
RET

REFRESCAR_MODO7:		// ----------------------------- DIAS (en rango del mes actual)
RET

// ############################################################################## //

OBTENER_DIAS_DEL_MES:

	PUSH	ZH
	PUSH	ZL
	PUSH	R16
	PUSH	R17
	PUSH	R19

	// verificar mes actual
	LDS		R16, MES_DECENA
	LDS		R17, MES_UNIDAD

	// Fusionar
	MOV		R19, R16
	LDI		R20, 10
	MUL		R19, R20
	ADD		R19, R17

	// Verificar en vector
	LDI		ZH, HIGH(DIAS_DEL_MES*2)
	LDI		ZL, LOW(DIAS_DEL_MES*2)
	DEC		R19									// Indice de Enero => 0
	LSL		R19									// mult por 2 porque dw ocupa 2 bytes

	ADD		ZL, R19
	LDI		R16, 0
	ADC		ZH, R16								// ZH = ZH + R16 + C (sumar acarreo si hubo)
	LPM		R21, Z								// Load Program Memory (cargar según puntero)

	POP		R19
	POP		R17
	POP		R16
	POP		ZL
	POP		ZH
	RET

DES_FUSIONAR:									// R18 => número por separar
	
	CLR		R20									// Registro para llevar conteo de resta de 10
	MOV		R21, R18							// copia del numero original

DIVISION:										// bucle para contar decenas
	CPI		R21, 10								// se repite mientras R21 sea mayor o igual a 10
	BRLT	FIN_DES_FUSIONAR					// Branch if Lower Than

	// R21 sigue siendo > 10
	SUBI	R21, 10								// R21 - 10
	INC		R20									// incremento en decenas
	RJMP	DIVISION							// repetir

FIN_DES_FUSIONAR:
	RET

/****************************************/
// Interrupt routines
TIM0_ISR:

	PUSH	R16
	IN		R16, SREG
	PUSH	R16

	// incrementar contador 1 segundo
	LDS		R16, C_SEGUNDOS
	INC		R16
	STS		C_SEGUNDOS, R16

	// modificar Display actual 
	LDS		R16, DISPLAY_ACTUAL
	INC		R16
	CPI		R16, 5								// martener margen de 4 displays
	BRNE	ACTUALIZAR1
	LDI		R16, 1

ACTUALIZAR1:
	STS		DISPLAY_ACTUAL, R16

	POP		R16
	OUT		SREG, R16
	POP		R16

	RETI

BTN_ISR:

	// ================================ //
	// PC0 => Decremento
	// PC1 => Incremento
	// PC2 => Modo
	// PC3 => Comodin (Guardar / Apagar Alarma)
	// ================================ //

	// Guardar en pila
	PUSH	R16								
	PUSH	R17	
	IN		R16, SREG							// Guardar Status Register
	PUSH	R16	

	// Lectura botones
	IN		R17, PINC

	SBRS	R17, 3								// Verificar Btn Comodin
	RJMP	REVISAR_MODO
	RJMP	BTN_COMODIN_PRESS

REVISAR_MODO:
	SBRS	R17, 2								// Verificar Btn Modo
	RJMP	REVISAR_INC_DEC
	RJMP	BTN_MODO_PRESS	

	// Los botones estarán habilitados según el modo actual
	//	  Los botones de INCREMENTO - DECREMENTO funcionan solo si el 
	//    modo es de configuración.

REVISAR_INC_DEC:
	LDS		R16, MODO

	// Si modo es < 4, Salir - BNTS DESHABILITADOS
	CPI		R16, 4
	BRLO	FIN_BTN_ISR

	// Si estamos en modo configuración
	SBRS	R17, 1	
	RJMP	REVISAR_DEC
	RJMP	BTN_INC_PRESS

REVISAR_DEC:
	SBRS	R17, 0
	RJMP	FIN_BTN_ISR
	RJMP	BTN_DEC_PRESS

	RJMP	FIN_BTN_ISR

	// ================================ //
	// BTN COMODIN PRESIONADO
	// ================================ //
BTN_COMODIN_PRESS:

	// alarma sonando?
	SBIS	PORTB, 4
	RJMP	VERIFICAR_GUARDADO

	// apagar alarma
	CBI		PORTB, 4
	LDI		R16, 0
	STS		ALARMA, R16
	RJMP	FIN_BTN_ISR

VERIFICAR_GUARDADO:
	
	// modo configuracion?
	LDS		R16, MODO
	CPI		R16, 4
	BRLO	FIN_BTN_ISR

	// Guardar nuevos valores
	LDI		R16, 1
	STS		GUARDAR_VALORES, R16
	RJMP	FIN_BTN_ISR

	// ================================ //
	// BTN MODO PRESIONADO
	// ================================ //
BTN_MODO_PRESS:

	LDS		R16, MODO
	CPI		R16, 9								// martener margen de 9 modos
	BREQ	CAMBIO_MODO
	INC		R16
	STS		MODO, R16
	RJMP	FIN_BTN_ISR

CAMBIO_MODO:
	LDI		R16, 1
	STS		MODO, R16
	RJMP	FIN_BTN_ISR

	// ================================ //
	// BTN DECREMENTO PRESIONADO
	// ================================ //
BTN_DEC_PRESS:
	
	LDI		R16, 1
	STS		BTN_DEC, R16
	RJMP	FIN_BTN_ISR

	// ================================ //
	// BTN INCREMENTO PRESIONADO
	// ================================ //
BTN_INC_PRESS:

	LDI		R16, 1
	STS		BTN_INC, R16

FIN_BTN_ISR:
	POP		R16
	OUT		SREG, R16							// Restaurar Status Register
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

// TABLA DE VALORES DIAS DE CADA MES
DIAS_DEL_MES:
    .dw 31	    // Enero 
    .dw 28	    // Febrero
    .dw 31	    // Marzo
    .dw 30	    // Abril
    .dw 31	    // Mayo
    .dw 30	    // Junio
    .dw 31	    // Julio
    .dw 31	    // Agosto
    .dw 30	    // Septiembre
    .dw 31	    // Octubre
	.dw 30	    // Noviembre
    .dw 31	    // Diciembre