#pragma once
#ifndef __UART_DRIVER_STDIO_HPP
#define __UART_DRIVER_STDIO_HPP 1

#include <memory>
#include "uart_simulator.hpp"

// Platform dependant context
struct uart_driver_stdio_ctx;

// UART driver implementation that uses STDOUT for communication
class uart_driver_stdio : virtual uart_driver {
    private:
        uart_driver_stdio_ctx* m_context;
        uart_driver_stdio(uart_driver_stdio_ctx*);
    public:
        virtual ~uart_driver_stdio();

        static std::unique_ptr<uart_driver> create(const uart_options& opts);

        virtual void poll(std::queue<uint8_t>& output) override;
        virtual void emit(uint8_t data) override;
};

#endif
