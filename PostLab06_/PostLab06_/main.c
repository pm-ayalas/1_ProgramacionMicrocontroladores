/*
 * PostLab06_.c
 *
 * Created: 4/29/2026 4:52:12 PM
 * Author: Paula Ayala
 * Description: 
 */
/****************************************/
// Encabezado (Libraries)
#define F_CPU 16000000UL
#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

/****************************************/
// Function prototypes
void setup(void);
void UART_init(void);
void UART_enviar(char c);
void write_str(char* texto); 
char UART_recibir(void);            // recibe un carácter (polling)
void ADC_init(void);                // inicializar ADC
uint16_t ADC_leer(uint8_t canal);   // leer el valor ADC
void enviar_numero(uint16_t num);   // enviar numero decimal por UART

/****************************************/
// Main Function
int main(void) {

    setup();
    UART_init();
    ADC_init();
    
    while (1) {
        // Mostrar menú
        write_str("\r\n*** MENU ***\r\n");
        write_str("1) Leer Potenciometro\r\n");
        write_str("2) Enviar Ascii\r\n");
        write_str("Opcion: ");
        
        char opcion = UART_recibir();   // esperar un carácter
        UART_enviar(opcion);             // eco
        write_str("\r\n");
        
        if (opcion == '1') {
            write_str("Valor ADC: ");
            uint16_t valor = ADC_leer(0);    // Potenciometro (PC0)
            enviar_numero(valor);
            write_str("\r\n");
        }
        else if (opcion == '2') {
            write_str("Ingrese un caracter: ");
            char c = UART_recibir();
            UART_enviar(c);                // eco
            write_str("\r\n");
            // Mostrar en los LEDs (nibble bajo en PORTB, nibble alto en PORTD)
            PORTB = c & 0x0F;              // bits 0-3
            PORTD = c & 0xF0;              // bits 4-7
        }
        else {
            write_str("Opcion invalida :c\r\n");
        }
        _delay_ms(100);   // pausa antes de reiniciar menú
    }
}

/****************************************/
// NON-Interrupt subroutines

void setup(void) {
    // SALIDAS = PB0-PB3 , PD4-PD7  
    DDRB = 0x0F;     
    DDRD = 0xF0;     
    
    // LEDs apagados
    PORTB = 0x00;
    PORTD = 0x00;
}

// 9600 Baud
void UART_init(void) {
    // UBRR = 103 -> 9600 baud - 16MHz
    UBRR0H = 0;
    UBRR0L = 103;
    
    // Habilitar transmisor y receptor (sin interrupción)
    UCSR0B = (1 << TXEN0) | (1 << RXEN0);
    
    // FORMATO: 8 bits datos, 1 bit parada, sin paridad
    UCSR0C = (1 << UCSZ01) | (1 << UCSZ00);
}

void UART_enviar(char c) {
    while (!(UCSR0A & (1 << UDRE0)));   // esperar buffer vacío
    UDR0 = c;
}

void write_str(char* texto) {
    for(uint8_t i = 0; *(texto+i) != '\0'; i++) {
        UART_enviar(*(texto+i));
    }
} 

// Recibe un carácter [Código en pausa hasta recibir un dato]
char UART_recibir(void) {
    while (!(UCSR0A & (1 << RXC0)));   // esperar dato recibido (polling)
    return UDR0;
}

// Inicializa ADC Ref AVcc, prescaler 128
void ADC_init(void) {
    ADMUX = (1 << REFS0);               // AVcc, canal 0 
    ADCSRA = (1 << ADEN) | (1 << ADPS2) | (1 << ADPS1) | (1 << ADPS0); // habilitar, prescaler 128
}

// Lee el valor de 10 bits 
uint16_t ADC_leer(uint8_t canal) {
    ADMUX = (ADMUX & 0xF0) | (canal & 0x0F); // seleccionar canal
    ADCSRA |= (1 << ADSC);                   // iniciar conversión
    while (ADCSRA & (1 << ADSC));            // esperar a que termine
    return ADC;                              // devuelve el registro ADC (10 bits)
}

// Envía un número entero de 16 bits (0-65535) en decimal por UART
void enviar_numero(uint16_t num) {
    char buffer[6];      // capacidad para 5 dígitos + terminador implícito
    uint8_t idx = 0;
    
    if (num == 0) {
        UART_enviar('0');
        return;
    }
    
    // Extraer dígitos de derecha a izquierda
    while (num > 0) {
        buffer[idx++] = '0' + (num % 10);
        num /= 10;
    }
    
    // Enviar en orden inverso (del dígito más significativo al menos)
    while (idx > 0) {
        UART_enviar(buffer[--idx]);
    }
}

/****************************************/
// Interrupt routines