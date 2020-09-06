#include "uart_system.hpp"
#include "log.hpp"

static std::string _name = "UART System";

uart_system::uart_system(simulator_driver& driver) :
    simulator_system(driver)
{
}

uart_system::~uart_system()
{
}

const std::string& uart_system::system_name() const { return _name; }

void uart_system::register_device(uint32_t device_id, const std::string& name) {
    uart_device dev;
    dev.device_id = device_id;
    dev.name = name;
    dev.last_tx_stb = 0;
    dev.last_rx_stb = 0;

    m_devices.emplace_back(dev);
}

void uart_system::tick(uint32_t device_id, int rx, int rx_stb, int tx_stb, unsigned char& tx, unsigned char& tx_available) {
    for(auto& dev : m_devices) {
        if(dev.device_id == device_id) {
            if(rx_stb && dev.last_rx_stb == 0) {
                // The target has written data. Emit the data to the underlying connection
                emit(device_id, rx);
            }

            if(tx_stb && dev.last_tx_stb == 0) {
                // The target has requested a read. Pop the data from the stack if the FIFO has data
                if(dev.transmit_buffer.size() > 0) {
                    tx = dev.transmit_buffer.front();
                    dev.transmit_buffer.pop();
                }
                else
                    tx = 0xFF;
            }

            dev.last_tx_stb = tx_stb;
            dev.last_rx_stb = rx_stb;

            tx_available = dev.transmit_buffer.size() > 0 ? 1 : 0;
        }
    }

    
}

void uart_system::tx(uint32_t device_id, uint8_t data) {
    for(auto& dev : m_devices) {
        if(dev.device_id == device_id) {
            dev.transmit_buffer.push(data);
            return;
        }
    }
}

void uart_system::emit(uint32_t device_id, uint8_t data) {
    simulator_message_t msg(SIM_MSG_UART_DATA_OUTPUT, sizeof(uart_data_message_t));
    uart_data_message_t* msg_data = (uart_data_message_t*)msg.data();
    msg_data->device = device_id;
    msg_data->data = data;

    m_driver.write(std::move(msg));
}