#pragma once
#ifndef __UART_DRIVER_HPP
#define __UART_DRIVER_HPP 1

#include <queue>
#include <stdint.h>

// Driver interface for UART
class uart_driver {
    public:
        virtual ~uart_driver() {}

        virtual void poll(std::queue<uint8_t>& output) = 0;
        virtual void emit(uint8_t data) = 0;

};

#endif
