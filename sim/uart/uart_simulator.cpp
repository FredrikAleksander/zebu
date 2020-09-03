#include "uart_simulator.hpp"
#include "uart_driver_stdio.hpp"
#include <iostream>

uart_simulator::~uart_simulator() {
}


std::unique_ptr<uart_simulator> uart_simulator::create(const uart_options& opts)
{
	std::unique_ptr<uart_driver> driver = uart_driver_stdio::create(opts);
    return std::unique_ptr<uart_simulator>(new uart_simulator(opts, std::move(driver)));
}

uart_simulator::uart_simulator(const uart_options& opts, std::unique_ptr<uart_driver>&& driver) :
	driver(std::move(driver)),
	last_rx_stb(0),
	last_tx_stb(0)
{
}

size_t uart_simulator::stack_size() const {
	return fifo.size();
}

unsigned char uart_simulator::pop_tx() {
	unsigned char d = fifo.front();
	fifo.pop();
	return d;
}

void uart_simulator::poll() {
	if(driver)
		driver->poll(fifo);
}

void uart_simulator::emit(unsigned char data) {
	if(driver)
		driver->emit(data);
}


void uart_simulator::tick(int i_rx, int i_rx_stb, int i_tx_stb, unsigned char& o_tx, unsigned char& o_tx_available) {
	poll(); // Check for input from underlying connection, which should feed the FIFO if data is available

	if(i_tx_stb && last_tx_stb == 0) {
		// The target has requested a read. Pop the data from the stack if the FIFO has data
		if(stack_size() > 0)
			o_tx = pop_tx();
		else
			o_tx = 0xFF;
	}
	if(i_rx_stb && last_rx_stb == 0) {
		// The target has written data. Emit the data to the underlying connection
		emit(i_rx);
	}

	last_tx_stb = i_tx_stb;
	last_rx_stb = i_rx_stb;

	o_tx_available = stack_size() > 0;
}