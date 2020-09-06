#include "simulator_system.hpp"
#include <queue>

#define SIM_MSG_UART_DATA_OUTPUT 0xEFC0
#define SIM_MSG_UART_DATA_INPUT  0xEFC1

struct uart_device {
    uint32_t            device_id;
    std::string         name;
    std::queue<uint8_t> transmit_buffer;
    int                 last_rx_stb;
    int                 last_tx_stb;
};

struct uart_data_message_t {
    uint32_t device;
    uint8_t  data;
};

class uart_system : public virtual simulator_system {
    private:
        std::vector<uart_device> m_devices;

        void emit(uint32_t device_id, uint8_t data);
    public:
        uart_system(simulator_driver& driver);
        virtual ~uart_system();

        virtual const std::string& system_name() const override;

        void register_device(uint32_t device_id, const std::string& name);
        void tick(uint32_t device_id, int rx, int rx_stb, int tx_stb, unsigned char& tx, unsigned char& tx_available);

        void tx(uint32_t device_id, uint8_t data);
};