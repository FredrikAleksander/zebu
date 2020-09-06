#include "kprint.h"

__sfr __at 0x80 UART_THR;
__sfr __at 0x80 UART_RBR;
__sfr __at 0x85 UART_LSR;

int kprintnstr(const char* str, int length) {
    int i = 0;
    for(; i < length; i++) {
        while((UART_LSR&1)==0) {}
        UART_THR=str[i];
    }
    return i;
}

int kprintzstr(const char* str) {
    if(str == 0)
        return -1;
    int i = 0;
    while(*str != 0) {
        while((UART_LSR&(1<<5))==0) {}
        UART_THR=*str;
        ++str,++i;
    }
    return i;
}