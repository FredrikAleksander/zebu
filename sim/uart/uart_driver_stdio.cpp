#include "uart_driver_stdio.hpp"
#include <poll.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <string.h>
#include <unistd.h>

struct uart_driver_stdio_ctx {
    int read_fd;
    int write_fd;
};


static void close_context(uart_driver_stdio_ctx* context) {
}

uart_driver_stdio::uart_driver_stdio(uart_driver_stdio_ctx* ctx) :
    m_context(ctx)
{
}

uart_driver_stdio::~uart_driver_stdio()
{
    close_context(m_context);
    delete m_context;
}

std::unique_ptr<uart_driver> uart_driver_stdio::create(const uart_options& opts) {
    auto context = new uart_driver_stdio_ctx { .read_fd = fileno(stdin), .write_fd = fileno(stdout) };
    return std::unique_ptr<uart_driver>(new uart_driver_stdio(context));
}

void uart_driver_stdio::poll(std::queue<uint8_t>& output) {
    int available;

    if(ioctl( 0, FIONREAD, &available) < 0) {
        fprintf( stderr, "ioctl failed: %s\n", strerror( errno));
        return;
    }

    if(available <= 0)
        return; 

    char buffer[64];

    while(available > 0) {
        int a = available > 64 ? 64 : available;
        int n = ::read(m_context->read_fd, buffer, a);
        for(int i = 0; i < n; i++) {
            output.push(buffer[i]);
        }
        available -= n;
    }
}

void uart_driver_stdio::emit(uint8_t data) {
    ::write(m_context->write_fd, &data, 1);
}