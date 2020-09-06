#pragma once
#ifndef __SIMULATOR_MESSAGE_HPP
#define __SIMULATOR_MESSAGE_HPP 1

#include <stdlib.h>
#include <stdint.h>

// Serialized simulator message
struct simulator_message_t {
    private:
        uint32_t m_tag;
        uint32_t m_len;
        void*    m_data;

        // In the future it is possible to implement better memory management,
        // but for now just use malloc/free
        static void* alloc_message(size_t len) {
            return malloc(len);
        }
        static void free_message(void* p) {
            free(p);
        }
    public:
        simulator_message_t(uint32_t tag, uint32_t len) :
            m_tag(tag),
            m_len(len),
            m_data(alloc_message(len))
        {}
        simulator_message_t(simulator_message_t&& other) :
            m_tag(other.m_tag),
            m_len(other.m_len),
            m_data(other.m_data)
        {
            other.m_tag = 0;
            other.m_len = 0;
            other.m_data = nullptr;
        }
        ~simulator_message_t() { free_message(m_data); }
        simulator_message_t(const simulator_message_t&) = delete;
        simulator_message_t& operator=(const simulator_message_t&) = delete;

        bool        valid() const  { return m_tag != 0; }
        uint32_t    tag() const    { return m_tag; }
        uint32_t    length() const { return m_len; }
        void*       data()         { return m_data; }
        const void* data() const   { return m_data; }
};

#endif