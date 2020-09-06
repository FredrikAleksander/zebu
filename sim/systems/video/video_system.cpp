#include "video_system.hpp"

static std::string _name = "Video System";

const std::string& video_system::system_name() const { return _name; }

void video_system::register_device(uint32_t device_id, const std::string& name) {
}

void video_system::tick(uint32_t device_id, int r, int g, int b, int hsync, int vsync) {
}