#pragma once
#ifndef __VIDEO_SYSTEM_HPP
#define __VIDEO_SYSTEM_HPP 1

#include "simulator_system.hpp"

class video_system : public virtual simulator_system
{
    public:
        video_system(simulator_driver& driver) :
            simulator_system(driver)
        {
        }

        virtual const std::string& system_name() const override;

        void register_device(uint32_t device_id, const std::string& name);
        void tick(uint32_t device_id, int r, int g, int b, int hsync, int vsync);
};

#endif