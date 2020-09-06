#pragma once
#ifndef __SIMULATOR_DRIVER_HPP
#define __SIMULATOR_DRIVER_HPP 1

#include "simulator_message.hpp"
#include "simulator_properties.hpp"

class simulator_base;

class simulator_driver {
    protected:
    public:
        virtual ~simulator_driver(){}

        virtual const simulator_properties& props() const = 0;
        virtual void write(simulator_message_t&& msg) = 0;
};

class dynamic_simulator_driver : public virtual simulator_driver {
    private:
        void* m_library;
    protected:
        simulator_base* m_simulator;
    public:
        dynamic_simulator_driver();
        virtual ~dynamic_simulator_driver();

        virtual int load(const std::string& simulator);
};

#endif