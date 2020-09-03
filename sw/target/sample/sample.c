__sfr __at 0x80 UART_THR;
__sfr __at 0x80 UART_RBR;
// __sfr __at 0x85 UART_LSR;

void main(void) {
    while(1) {
        int c = UART_RBR;
        UART_THR = c;
    }
}