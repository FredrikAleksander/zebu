#include <stdlib.h>
#include "Vsimulator.h"
#include "verilated.h"

int main(int argc, char* argv[]) {
    // Initialize Verilators variables
	Verilated::commandArgs(argc, argv);

	// Create an instance of our module under test
	Vsimulator *tb = new Vsimulator;

	// Tick the clock until we are done
	while(!Verilated::gotFinish()) {
		tb->i_mclk = 1;
		tb->eval();
		tb->i_mclk = 0;
		tb->eval();
	} exit(EXIT_SUCCESS);
    return 0;
}