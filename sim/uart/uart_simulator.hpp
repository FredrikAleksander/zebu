#pragma once
#ifndef __UART_SIMULATOR_HPP
#define __UART_SIMULATOR_HPP 1

#include <memory>
#include "uart_driver.hpp"

struct uart_options {
    int port;
};

class uart_simulator {
    private:
        uart_options m_options;
        uart_simulator(const uart_options& opts, std::unique_ptr<uart_driver>&& driver);

        std::unique_ptr<uart_driver> driver;

        int last_rx_stb;
        int last_tx_stb;

        std::queue<unsigned char> fifo;
        unsigned char pop_tx();
    protected:

        void emit(unsigned char data);
        void poll();
        size_t stack_size() const;
    public:
        virtual ~uart_simulator();
    public:
        enum status_t {
            CLOSED
        };

        status_t status() const;

        virtual void tick(int i_rx, int i_rx_stb, int i_tx_stb, unsigned char& o_tx, unsigned char& o_tx_available);

        void close();

        static std::unique_ptr<uart_simulator> create(const uart_options& opts);
};

#endif