#include <stdlib.h>
#include "Vsimulator.h"
#include "verilated.h"
#include "testbench.hpp"

int main(int argc, char* argv[]) {
	const char* tracePath = NULL;
	const char* romPath = NULL;
	long romSize = 0;
	char* romData = NULL;

    // Initialize Verilators variables
	Verilated::commandArgs(argc, argv);

	for(int i = 1; i < argc; i++) {
		if(strcmp(argv[i], "--trace") == 0 && i+1 < argc) {
			printf("Writing trace file: %s\n", argv[i+1]);
			tracePath = argv[i+1];
			i++;
		}
		else if(strcmp(argv[i], "--rom") == 0 && i+1 < argc) {
			printf("Using ROM file: %s\n", argv[i+1]);
			romPath = argv[i+1];
			i++;
		}
	}

	testbench<Vsimulator>* tb = new testbench<Vsimulator>();

	if(tracePath != NULL) {
		tb->opentrace(tracePath);
	}

	if(romPath != NULL) {
		FILE* romFile = fopen(romPath, "rb");
		fseek(romFile, 0, SEEK_END);
		romSize = ftell(romFile);
		fseek(romFile, 0, SEEK_SET);

		if(romSize > 512*1024) {
			printf("Warning: ROM binary is larger than ROM memory\n");
		}

		romData = reinterpret_cast<char*>(malloc(romSize));
		if(romData == NULL) {
			fprintf(stderr, "Failed allocate memory for ROM\n");
			return 1;
		}
		if(fread(romData, romSize, 1, romFile) != romSize) {
			fprintf(stderr, "Failed to read ROM file\n");
			return 1;
		}
	}

	auto* ramPtr = tb->m_core->simulator__DOT__ram__DOT__memory;
	auto* romPtr = tb->m_core->simulator__DOT___rom__DOT__memory;

	memset(ramPtr, 0xAA, 512*1024);

	if(romData) {
		memcpy(romPtr, romData, romSize);
		free(romData);
	} else {
		memset(romPtr, 0xFF, 512*1024);
	}


	tb->reset(2);

	// Tick the clock until we are done
	while(!Verilated::gotFinish()) {
		tb->tick();
	} 
	tb->close();
	delete tb;
	exit(EXIT_SUCCESS);
    return 0;
}