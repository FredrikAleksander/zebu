#pragma once
#ifndef __SIMULATOR_SYSTEM_HPP
#define __SIMULATOR_SYSTEM_HPP 1

#include "simulator_driver.hpp"

class simulator_system {
    protected:
        simulator_driver& m_driver;
    public:
        simulator_system(simulator_driver& driver) :
            m_driver(driver)
        {   
        }
        virtual ~simulator_system() {}

        virtual const std::string& system_name() const = 0;
};

#endif