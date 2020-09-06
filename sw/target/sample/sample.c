#include "kprintf.h"

void detect_device(int num) {
    kprintf(" Device #%d: NONE\n", num);
}

void detect_memory(void) {
    int memory = 32; // Base system has 512KB RAM
    kprintf(" Memory: % 4dKB", memory << 4);
    for(int i = 0; i < 192; i++) {
        // Check if block `i` is valid RAM
        // TODO: Move left 1000
        kprintf("\033[999D");
        kprintf(" Memory: % 4dKB", memory << 4);
    }
}

void detect_disks(void) {
    kprintf(" Disk Drives:\n");
    kprintf("   No disk drives detected!");
}

void main(void) {
    kprintf("\033[?25l"); // Hide cursor
    kprintf("\033[?12l");
    kprintf("\033[2J\033[H"); // Clear screen, move to home position
    kprintf("\033[44m\033[37;1m ZEBU BIOS    release 0.1\033[K");
    kprintf("\033[0m"); // Reset colors
    kprintf("\n\n");

    detect_memory();
    
    kprintf("\n\n");

    for(unsigned char i = 0; i < 4; i++) {
        detect_device(i);
    }

    kprintf("\n\n");

    detect_disks();

    kprintf("\n\n");

    kprintf("\033[?25h");
    kprintf("\033[?12h");
}