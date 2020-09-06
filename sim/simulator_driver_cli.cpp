#include "simulator_driver.hpp"
#include "simulator_base.hpp"
#include "systems/uart/uart_system.hpp"
#include "systems/video/video_system.hpp"
#include "log.hpp"
#include <memory>
#include <queue>
#include <string.h>

class simulator_driver_cli : public virtual dynamic_simulator_driver {
    private:
        std::string                     m_library_path;
        simulator_properties            m_properties;
        std::queue<simulator_message_t> m_messages;

        uart_system*                    m_uart_system;
        video_system*                   m_video_system;
    public:
        simulator_driver_cli() :
            m_library_path(),
            m_uart_system(nullptr),
            m_video_system(nullptr)
        {
        }

        virtual ~simulator_driver_cli() {
        };

        virtual const simulator_properties& props() const override {
            return m_properties;
        }

        void process_commandline(int argc, char* argv[]) {
            char scanbuf_k[256];
            char scanbuf_v[256];

            int position = 0;

            for(int i = 1; i < argc; i++) {
                if(strlen(argv[i]) > 256) {
                    LOG_INFO("Command line argument too large, ignored: %s", argv[i]);
                    continue;
                }

                int matches = sscanf(argv[i], "--%[^= ]=%s", scanbuf_k, scanbuf_v);
                if(matches == 1) {
                    m_properties[scanbuf_k] = "true";
                    continue;
                }
                if(matches == 2) {
                    m_properties[scanbuf_k] = scanbuf_v;
                    continue;
                }

                if(position == 0) {
                    LOG_INFO("Library Path: %s", argv[i]);
                    m_library_path = argv[i];
                }

                // Positional argument
                position++;
            }

            for(auto& prop : m_properties) {
                LOG_INFO("Property %s = %s", prop.first.c_str(), prop.second.c_str());
            }
        }

        int run() {
            int result = 0;
            if((result = load(m_library_path)) != 0) {
                // TODO: Error
                return result;
            }

            LOG_INFO("Enumerating simulator systems:");

            for(auto& sys : (*m_simulator)) {
                LOG_INFO("  %s", sys->system_name().c_str());

                if(m_uart_system == nullptr)
                    m_uart_system = dynamic_cast<uart_system*>(sys.get());
                if(m_video_system == nullptr)
                    m_video_system = dynamic_cast<video_system*>(sys.get());
            }

            if(m_uart_system) {
                // Enumerate UART devices
                LOG_INFO("Enumerating UART devices:");
            }

            if(m_video_system) {
                // Enumerate video devices
                LOG_INFO("Enumerating video devices:");
            }

            LOG_INFO("Running simulation");
            m_simulator->reset(100);
            m_simulator->start();
            do {
                m_simulator->tick();
                while(m_messages.size()) {
                    process_message(m_messages.front());
                    m_messages.pop();
                }
            } while(m_simulator->get_state() != simulator_state_t::FINISHED);
        }

        void process_message(const simulator_message_t& msg) {
             uart_data_message_t* uart_data = nullptr;
             switch(msg.tag()) {
                 case SIM_MSG_UART_DATA_OUTPUT:
                    uart_data = (uart_data_message_t*)msg.data();
                    fputc(uart_data->data, stdout);
                    fflush(NULL);
                    break;
                 default:
                    LOG_WARN("Unknown message: 0x%08x", msg.tag());
                    break;
             }
        }

        virtual void write(simulator_message_t&& msg) override {
            m_messages.emplace(std::move(msg));
        }
};

int main(int argc, char* argv[]) {
    std::string simulator_library;

    std::unique_ptr<simulator_driver_cli> cli = std::unique_ptr<simulator_driver_cli>(new simulator_driver_cli());
    cli->process_commandline(argc, argv);
    return cli->run();
}