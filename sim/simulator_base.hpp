#pragma once
#ifndef __SIMULATOR_BASE_HPP
#define __SIMULATOR_BASE_HPP 1

#include <memory>
#include <stdint.h>
#include <string>
#include <vector>
#include "simulator_system.hpp"

enum class device_tag_t {
    UART,
    DISPLAY
};

struct simulator_device {
    uint32_t     id;
    device_tag_t tag;
    std::string  name;
};

enum class simulator_state_t {
    WAITING = 0,  // Simulator is waiting to start
    RUNNING = 1,  // Simulator is running
    STOPPED = 2,  // Simulator has stopped
    FINISHED = 3, // Simulator has finished executing
    RESETTING = 4  // Simulator is resetting
};


class simulator_base {
    public:
        using state_t = simulator_state_t;
        using simulator_system_ptr_t = std::unique_ptr<simulator_system>;
        using systems_t = std::vector<simulator_system_ptr_t>;
        using iterator_t = systems_t::const_iterator;
        

        virtual ~simulator_base() {}

        virtual iterator_t begin()     const  = 0;
        virtual iterator_t end()       const  = 0;
        virtual state_t    get_state() const  = 0;
        virtual void       start()            = 0;
        virtual void       stop()             = 0;
        virtual void       reset(uint64_t ns) = 0;
        virtual void       tick()             = 0;
};

#endif