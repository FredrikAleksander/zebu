#include <algorithm>
#include <memory>
#include <functional>
#include <unordered_map>
#include <vector>
#include "verilated_vcd_c.h"
#include "Vsimulator.h"
#include "log.hpp"
#include "simulator_clock.hpp"
#include "simulator_driver.hpp"
#include "simulator_base.hpp"

#include "systems/uart/uart_system.hpp"
#include "systems/video/video_system.hpp"

// Improved simulator base class.
// The simulator core concept is very simple. At every eval loop of the simulation
// clocks are advanced, and when a falling edge is detected on a clock, that clock
// `ticks`, calling a series of callbacks registered with that clock.
// A callback may be called forever, once or until a condition is true
// Multiple abstractions are built on top of this core concept, but at the most basic,
// that is how the simulator runs.
//
// The simulator also supports simulated devices, like UART's and display monitors.
// These are registered with specialized functions that adds the underlying clock tick
// event, decorating it as needed for the device, aswell as registering device metadata.
// Custom devices may be added and used in a similar manner.
//
// It is possible to also create callbacks that are called on every single eval loop
// with same possibilites of allowing it to run forever, only once or until a condition
// is true
//
// A callback may suspend execution by calling the simulator stop() method.
// Combined with the ability to execute a callback until a condition is true,
// it is easy to implement any type of breakpoint, such as breaking on a CPU program counter
// reaching a certain location, breaking on a specific type of bus cycle, break on vblank,
// break on memory value changed etc
//
// About threading. The simulation should run in its own thread. Callbacks, monitors, device simulators 
// etc, are called in the simulator thread. For the most part, most custom code should live inside 
// the simulator thread, but at specific points it should serialize state and pass it on to the host.
//
// Verilator tracing is off by default for performance reason, but can be turned on if needed.
//
// Future improvements would be to the possibility of driving the simulator over a TCP socket.
// That way the simulator can run in it's own process, possibly on another computer. That would
// allow running the simulator on a powerful networked machine, but having the GUI and controls
// on a weaker laptop
template<typename DUT=Vsimulator>
class simulator : public virtual simulator_base {
    public:
        using dut_func_t = std::function<void(DUT&)>;
        using device_map_t = std::unordered_map<uint32_t, simulator_device>;
        using uart_tick_t = std::function<void(int, int, int, unsigned char&, unsigned char&)>;
        using display_tick_t = std::function<void(int, int, int, int, int)>;
        using reset_clear_t = std::function<void(DUT&)>;
        using reset_set_t = std::function<void(DUT&)>;
        using clocks_t = std::vector<simulator_clock>;
    private:
        VerilatedVcdC*       m_trace;
    protected:
        simulator_properties m_props;
    private:
        simulator_driver*    m_driver;
        uint64_t             m_time_ps;
        uint32_t             m_lastDeviceId = (0U-1U);
        std::unique_ptr<DUT> m_device;
        state_t              m_state;
        device_map_t         m_devices;
        clocks_t             m_clocks;
        dut_func_t           m_reset_clear;
        dut_func_t           m_reset_set;
        systems_t            m_systems;

        uart_system*         m_uart_system;
        video_system*        m_video_system;
    protected:
        DUT& device() {
            return *m_device;
        }
        void configure(const std::string& key, std::function<void(const std::string&)> action) {
            auto i = m_props.find(key);
            if(i != m_props.end()) {
                action(i->second);
            }
        }
    private:
        void sim_eval() {
            m_device->eval();
        }

        int sim_tick() {
            if(m_clocks.size() == 0) {
				fprintf(stderr, "ERROR: Cannot run simulation with no clocks\n");
				exit(1);
			}

			uint64_t min_time = std::min_element(m_clocks.begin(), m_clocks.end())->time_to_edge();
			sim_eval();
			for(auto&& clk : m_clocks) {
				auto inc = clk.advance(min_time);
				clk.set(inc);
			}

			m_time_ps += min_time;

			sim_eval();

			if (m_trace) {
				m_trace->dump(m_time_ps);
				m_trace->flush();
			}

            for(auto& clock : m_clocks) {
                if(clock.falling_edge()) {
                    clock.tick();
                }
            }
        }

        void set_state(simulator_state_t st) {
            if(m_state == simulator_state_t::FINISHED || m_state == st)
                return;
            // TODO: Emit event
            m_state = simulator_state_t::RUNNING;
        }
    protected:
        void dispatch(std::function<void()>&& callback) {
            callback();
        }

        void uart_device_tick(uint32_t device_id, int rx, int rx_stb, int tx_stb, unsigned char& tx, unsigned char& tx_available) {
            m_uart_system->tick(device_id, rx, rx_stb, tx_stb, tx, tx_available);
        }

        void display_device_tick(uint32_t device_id, int r, int g, int b, int hsync, int vsync) {
            m_video_system->tick(device_id, r, g, b, hsync, vsync);
        }
    public:
        void add_clock(const std::string& name, uint64_t freq, std::function<int(DUT&)>&& getter, std::function<void(DUT&, int)>&& setter) {
            for(auto& clk : m_clocks) {
                if(clk.name() == name) {
                    LOG_ERROR("Conflicting clock definitions");
                    return;
                }
            }
            auto device = m_device.get();
            m_clocks.emplace_back(simulator_clock(name, simulator_clock::freq_period(freq), [device, getter{std::move(getter)}]() {
                return getter(*device);
            }, [device, setter{std::move(setter)}](int i) {
                setter(*device, i);
            }));
        }

        // Add a simulated device
        uint32_t add_device(const std::string& name, const std::string& clock, device_tag_t tag, std::function<void(simulator&, DUT&, uint32_t)>&& binder) {
            // TODO: Verify device does not conflict with existing device
            
            simulator_clock* clockp = nullptr;
            for(auto& clk : m_clocks) {
                if(clk.name() == clock) {
                    clockp = &clk;
                    break;
                }
            }
            if(clockp == nullptr) {
                LOG_ERROR("No such clock");
            }

            auto  device_id = ++m_lastDeviceId;
            auto  device = m_device.get();
            m_devices.emplace(std::pair<uint32_t, simulator_device>(device_id, { .id=device_id, .tag=tag, .name=name }));
            on([device_id, binder{std::move(binder)}](simulator& sim, DUT& dut) {
                binder(sim, dut, device_id);
            }, clock, false);
            return device_id;
        }

        void add_uart(const std::string& name, const std::string& clock, std::function<void(simulator&, DUT&, const uart_tick_t&)>&& tick_binder) {
            auto device_id = add_device(name, clock, device_tag_t::UART, [this, binder{std::move(tick_binder)}] (simulator& sim, DUT& dut, uint32_t device_id) {
                binder(sim, dut, [this, device_id](int rx, int rx_stb, int tx_stb, unsigned char& tx, unsigned char& tx_available){ 
                    this->uart_device_tick(device_id, rx, rx_stb, tx_stb, tx, tx_available);
                });
            });

            m_uart_system->register_device(device_id, name);
        }

        void add_display(const std::string& name, const std::string& clock, std::function<void(simulator&, DUT&, const display_tick_t&)>&& tick_binder) {
            auto device_id = add_device(name, clock, device_tag_t::DISPLAY, [this, binder{std::move(tick_binder)}] (simulator& sim, DUT& dut, uint32_t device_id) {
                binder(dut, [this, device_id](int r, int g, int b, int hsync, int vsync){
                    this->display_device_tick(device_id, r, g, b, hsync, vsync);
                });
            });

            m_video_system->register_device(device_id, name);
        }

        // Register a callback to be called on every tick of specified clock. If `once` is true,
        // the callback is only called once
        void on(std::function<void(simulator&, DUT&)>&& callback, const std::string& clock, bool once = false) {
            for(auto& clk : m_clocks) {
                if(clk.name() == clock) {
                    auto sim = this;
                    auto dev = m_device.get();
                    clk.on([sim, dev, callback{std::move(callback)}](){
                        callback(*sim, *dev);
                    }, once);
                    return;
                }
            }
            LOG_ERROR("Cannot find specified clock");
        }

        // Register a callback to called on every evaluation loop
        void on(std::function<void(simulator&, DUT&)>&& callback, bool once) {
        }

        // Register a callback that is called on every tick of clock until it returns true.
        // After the callback returns true, the callback will no longer be called
        void until(std::function<bool(simulator&, DUT&)>&& callback, const std::string& clock) {
        }

        // Register is a callback that is called on every evaluation loop until it returns true.
        // After the callback returns true, the callback will no longer be called
        void until(std::function<bool(simulator&, DUT&)>&& callback) {
        }
    public:
        simulator(simulator_driver* driver, const simulator_properties& props, std::function<void(DUT&)>&& reset_clear, std::function<void(DUT&)>&& reset_set)
            : m_trace(nullptr),
              m_time_ps(0),
              m_props(props),
              m_driver(driver),
              m_device(std::move(std::unique_ptr<DUT>(new DUT))),
              m_reset_clear(reset_clear),
              m_reset_set(reset_set)
        {
            auto uart_system_ptr = simulator_system_ptr_t(new uart_system(*driver));
            auto video_system_ptr = simulator_system_ptr_t(new video_system(*driver));

            m_uart_system = dynamic_cast<uart_system*>(uart_system_ptr.get());
            m_video_system = dynamic_cast<video_system*>(video_system_ptr.get());

            m_systems.emplace_back(std::move(uart_system_ptr));
            m_systems.emplace_back(std::move(video_system_ptr));

            configure("trace", [this](const std::string& path){ this->dump_trace(path); });
        }

        virtual iterator_t begin() const override { return m_systems.begin(); }
        virtual iterator_t end() const override { return m_systems.end(); }

        virtual ~simulator()
        {
            if (m_trace) {
				m_trace->close();
				m_trace = NULL;
			}
        }

        virtual state_t get_state() const override {
            return m_state;
        }

        virtual void start() override {
            if(m_state != simulator_state_t::FINISHED) {
                set_state(simulator_state_t::RUNNING);
            }
        }

        virtual void stop() override {
            set_state(simulator_state_t::STOPPED);
        }

        virtual void reset(uint64_t ns) override {
            assert(ns > 0);

            bool resume = m_state == state_t::RUNNING;

            set_state(state_t::RESETTING);

            auto time_target = m_time_ps + (ns * 1000ULL);

            m_reset_set(*m_device);
            while(m_time_ps < time_target) {
                sim_tick();
            }
            m_reset_clear(*m_device);

            if(resume)
                set_state(state_t::RUNNING);
            else
                set_state(state_t::STOPPED);
        }

        virtual void tick() override {
            if(m_state == state_t::RUNNING) {
                sim_tick();
            }
        }

        void dump_trace(const std::string& path) {
			Verilated::traceEverOn(true);
			if (!m_trace) {
				m_trace = new VerilatedVcdC;
				device().trace(m_trace, 99);
				m_trace->spTrace()->set_time_resolution("ps");
				m_trace->spTrace()->set_time_unit("ps");
				m_trace->open(path.c_str());
			}
        }
};

extern "C" simulator_base* simulator_entry_point(simulator_driver*);