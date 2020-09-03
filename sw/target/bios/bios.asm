    OUTPUT "bios.rom"

UART equ 0x80
UART_RBR: equ UART+0x0
UART_THR: equ UART+0x0
UART_DLL: equ UART+0x0
UART_DLM: equ UART+0x1
UART_LCR: equ UART+0x3
UART_LSR: equ UART+0x5
UART_MCR: equ UART+0x04

    MACRO DRV_UARTRD
.loop:
    ; Loop until bit 0 of Line Status Register is 1
    IN a, (UART_LSR)
    BIT 0, a
    JR z, .loop 
    ; Read data from Receiver Buffer Register
    IN a, (UART_RBR)
    ENDM

    ; Write byte to UART from register A
    ; -----------------------------------------
    ; Modifies: A
    MACRO DRV_UARTWR
    EX af, af'
.loop:
    ; Loop until bit 5 of Line Status Register is 1
    IN a, (UART_LSR)
    BIT 5, a
    JR z, .loop

    ; Write data to Transmitter Holding Register
    EX af, af'
    OUT (UART_THR), a

    ENDM

    ; Init UART
    ; ---------------------------
    ; Set Line Control Register to use 8 bit data, 1 stop bit, no parity check, and DLAB=1
    LD a, %10000011
    OUT (UART_LCR), a
    NOP

    ; Set least significant byte of Divisor Latch to 12
    LD a, 0Ch
    OUT (UART_DLL), a
    NOP
    ; And the most significant byte to 0, for a divisor of
    ; 12, for a speed of 9600 bps
    LD a, 00h
    OUT (UART_DLM), a
    NOP
    
    ; Set DLAB bit of Line Control Register to 0
    LD a, %00000011
    OUT (UART_LCR), a
    NOP

    LD a, 'W'
    DRV_UARTWR
    LD a, 'e'
    DRV_UARTWR
    LD a, 'l'
    DRV_UARTWR
    LD a, 'c'
    DRV_UARTWR
    LD a, 'o'
    DRV_UARTWR
    LD a, 'm'
    DRV_UARTWR
    LD a, 'e'
    DRV_UARTWR
    LD a, ' '
    DRV_UARTWR
    LD a, 't'
    DRV_UARTWR
    LD a, 'o'
    DRV_UARTWR
    LD a, ' '
    DRV_UARTWR
    LD a, 't'
    DRV_UARTWR
    LD a, 'h'
    DRV_UARTWR
    LD a, 'e'
    DRV_UARTWR
    LD a, ' '
    DRV_UARTWR
    LD a, 'm'
    DRV_UARTWR
    LD a, 'a'
    DRV_UARTWR
    LD a, 'c'
    DRV_UARTWR
    LD a, 'h'
    DRV_UARTWR
    LD a, 'i'
    DRV_UARTWR
    LD a, 'n'
    DRV_UARTWR
    LD a, 'e'
    DRV_UARTWR
    LD a, '\n'
    DRV_UARTWR

LOOP:
    ; Set hold register, Chip Select to device #1, no clock divider
    LD c, 0xA1
    LD a, 0x80
    OUT (c), a

    ; Write 3 bytes to SPI device #1
    LD c, 0xA0
    LD a, 0xDE
    OUT (c), a
    LD a, 0xAD
    OUT (c), a
    LD a, 0xAA
    OUT (c), a

    ; Clear hold registers
    LD c, 0xA1
    LD a, 0x00
    OUT (c), a

    ; Echo
    DRV_UARTRD
    DRV_UARTWR
    
    jr LOOP