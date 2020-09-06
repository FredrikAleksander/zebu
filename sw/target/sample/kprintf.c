#include <stdio.h>
#include <stdarg.h>
#include "kprint.h"

char kprintf_buf[80];

int kprintf(const char* fmt, ...) {
    va_list va;
    va_start(va, fmt);
    int n = vsnprintf(kprintf_buf, 80, fmt, va);
    va_end(va);
    if(n < 0)
        return n;
    kprintzstr(kprintf_buf);
    return n;
}