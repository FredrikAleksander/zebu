#include "simulator.hpp"
#include "Vsimulator.h"

#if defined(_MSC_VER)
    //  Microsoft 
    #define EXPORT __declspec(dllexport)
    #define IMPORT __declspec(dllimport)
#elif defined(__GNUC__)
    //  GCC
    #define EXPORT __attribute__((visibility("default")))
    #define IMPORT
#else
    #define EXPORT
    #define IMPORT
    #pragma warning Unknown dynamic link import/export semantics.
#endif

class zebusim : public virtual simulator<Vsimulator> {
    public:
        zebusim(simulator_driver* driver)
            : simulator(driver, driver->props(), [](Vsimulator& dut) { dut.i_reset = 0; }, [](Vsimulator& dut) { dut.i_reset = 1; })
        {
            add_clock("Master Clock", 32'000'000ULL, [](auto& dut) { return dut.i_clk; }, [](auto& dut, int i) { dut.i_clk = i; });
            add_uart("NS16450", "Master Clock", [](auto& sim, auto& dut, auto& tick) {
                tick(dut.o_tx, dut.o_tx_stb, dut.o_rx_stb, dut.i_rx, dut.i_rx_available);
            });

            configure("rom", [this](const std::string& romPath){ this->load_rom(romPath); });
            memset(device().simulator__DOT__ram__DOT__memory, 0, 512*1024);
        }

        void load_rom(const std::string& path) {
            std::vector<uint8_t> data;
            FILE* fp = fopen(path.c_str(), "rb");
            if(fp == nullptr) {
                LOG_ERROR("Failed to open ROM file: %s", path.c_str());
                return;
            }
            fseek(fp, 0, SEEK_END);
            auto endp = ftell(fp);
            fseek(fp, 0, SEEK_SET);

            if(endp <= 0) {
                fclose(fp);
                LOG_ERROR("ROM file is empty: %s", path.c_str());
                return;
            }
            data.resize(endp);
            long ofs = 0;
            while(ofs < endp) {
                auto n  = fread(&data.data()[ofs], 1, endp-ofs, fp);
                ofs    += n;
            }
            fclose(fp);

            load_rom(data, 0, data.size());
        }

        // TODO: Create a memory management abstraction in the base class which supports
        // registering multiple memory regions in multiple address spaces,
        // and the ability to inspect and modify them
        void load_rom(const std::vector<uint8_t>& data, size_t offset, size_t length) {
            auto state = get_state();
            if(state != state_t::STOPPED && state != state_t::WAITING) {
                LOG_WARN("Cannot load ROM if simulator has not stopped");
                return; 
            }
            
            if(offset + length > 512*1024) {
                LOG_WARN("Warning: ROM binary is larger than ROM memory");
                length = 512*1024 - offset;
            }

	        auto* romPtr = device().simulator__DOT___rom__DOT__memory;
            memcpy(&romPtr[offset], data.data(), length);
        }
};

EXPORT simulator_base* simulator_entry_point(simulator_driver* driver) {
    return new zebusim(driver);
}