#include "simulator_driver.hpp"

#ifdef _WIN32
#else
#include <dlfcn.h>
#endif

extern "C" {
    typedef simulator_base* (*simulator_entry_point_t)(simulator_driver*);
}

dynamic_simulator_driver::dynamic_simulator_driver() :
    m_simulator(nullptr),
    m_library(nullptr)
{
}

dynamic_simulator_driver::~dynamic_simulator_driver() {
#ifdef _WIN32
#else
    if(m_library != nullptr)
        dlclose(m_library);
#endif
}

int dynamic_simulator_driver::load(const std::string& simulator) {
    if(m_library != NULL)
        return m_simulator != nullptr ? 0 : -1;
#ifdef _WIN32
#else
    m_library = dlopen(simulator.c_str(), RTLD_NOW);
    simulator_entry_point_t entry_point = (simulator_entry_point_t)dlsym(m_library, "simulator_entry_point");
    if(entry_point == nullptr) {
        // TODO: Error
        fprintf(stderr, "ERROR: Failed to find simulator entry point\n");
        return -1;
    }
    m_simulator = entry_point(this);
    return m_simulator != nullptr ? 0 : -1;
#endif
}