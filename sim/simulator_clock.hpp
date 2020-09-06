#pragma once
#ifndef __SIMULATOR_CLOCK_HPP
#define __SIMULATOR_CLOCK_HPP 1

#include <functional>

class simulator_clock {
    public:
        using tick_t = std::function<void()>;
    private:
        std::string m_name;

        uint64_t m_increment_ps;
        uint64_t m_now_ps;
        uint64_t m_last_posedge_ps;
        uint64_t m_ticks;

        std::function<int(void)> getter;
        std::function<void(int)> setter;

        std::vector<tick_t> callbacks;
    public:
        simulator_clock(const std::string& name, uint64_t increment_ps, std::function<int(void)> getter, std::function<void(int)> setter) :
            m_name(name),
            m_increment_ps((increment_ps>>1)&-2l),
            m_now_ps(((increment_ps>>1)&-2l)+1),
            m_last_posedge_ps(0),
            m_ticks(0),
            getter(getter),
            setter(setter)
        {
        }

        const std::string& name() const {
            return m_name;
        }

        void tick() {
            for(auto& callback : callbacks) {
                callback();
            }
        }

        void on(tick_t&& tck, bool once = false) {
            callbacks.emplace_back(std::move(tck));
        }

        void set(int signal) {
            setter(signal);
        }

        int get() {
            return getter();
        }

        static uint64_t freq_period(uint64_t freq) {
            double	tmp = 1e12 / (double)freq;
		    return (uint64_t)tmp;
        }

        uint64_t time_to_edge() const {
            if (m_last_posedge_ps > m_now_ps) {
                unsigned long ul;

                // Should never happen
                fprintf(stderr, "Error in %s:%d\n",__FILE__,
                    __LINE__);

                assert(0);

                ul = m_last_posedge_ps - m_now_ps;
                ul /= m_increment_ps;

                ul = m_now_ps + ul * m_increment_ps;
                return ul;
            } else if (m_last_posedge_ps + m_increment_ps > m_now_ps)
                return m_last_posedge_ps + m_increment_ps - m_now_ps;
            else if (m_last_posedge_ps + 2*m_increment_ps > m_now_ps)
                return m_last_posedge_ps + 2*m_increment_ps - m_now_ps;
            else {
                // Should never happen
                fprintf(stderr, "Error in %s:%d\n",__FILE__,
                    __LINE__);
                assert(0);
                return 2*m_increment_ps;
            }
        }

        int advance(uint64_t itime) {
            m_now_ps += itime;

            if(m_now_ps >= m_last_posedge_ps + 2 * m_increment_ps) {
                m_last_posedge_ps += 2 * m_increment_ps;
                m_ticks++;
                return 1;
            }
            else if(m_now_ps >= m_last_posedge_ps + m_increment_ps) {
                return 0;
            }
            else {
                return 1;
            }
        }

        bool rising_edge() const {
            return m_now_ps == m_last_posedge_ps;
        }

        bool falling_edge() const {
            return m_now_ps == m_last_posedge_ps + m_increment_ps;
        }
};

inline bool operator <(const simulator_clock& a, const simulator_clock& b) {
    return a.time_to_edge() < b.time_to_edge();
}

#endif