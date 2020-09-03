#pragma once
#ifndef __testbench_HPP
#define __testbench_HPP 1

#include <verilated_vcd_c.h>
#include <tb_clock.hpp>
#include <vector>
#include <bits/stdc++.h> 
#include "uart/uart_simulator.hpp"

template<class MODULE> class testbench {
	protected:
	// Need to add a new class variable
		VerilatedVcdC*        m_trace;
		unsigned long	      m_tickcount;
		uint64_t              m_time_ps;
		std::vector<tb_clock> m_clocks;
		std::unique_ptr<uart_simulator> m_uart_simulator;
	public:
		MODULE	*m_core;
	protected:
		void eval() {
			m_core->eval();
		}
	public:
		testbench(int master_clock_freq, const uart_options& uart_opts) : 
			m_trace(NULL),
			m_tickcount(0),
			m_time_ps(0),
			m_core(new MODULE),
			m_uart_simulator(uart_simulator::create(uart_opts))
		{
			m_core->i_rx = 0xFF;
			m_clocks.push_back(tb_clock(tb_clock::freq_period(master_clock_freq), [this]() { return this->m_core->i_clk; }, [this](int x) { this->m_core->i_clk = x; }));
			m_clocks.push_back(tb_clock(tb_clock::freq_period(1843200), [this]() { return this->m_core->i_baudclk; }, [this](int x) { this->m_core->i_baudclk = x; }));
		}

		virtual	void opentrace(const char *vcdname) {
			Verilated::traceEverOn(true);
			if (!m_trace) {
				m_trace = new VerilatedVcdC;
				m_core->trace(m_trace, 99);
				m_trace->spTrace()->set_time_resolution("ps");
				m_trace->spTrace()->set_time_unit("ps");
				m_trace->open(vcdname);
			}
		}

		virtual void	close() {
			if (m_trace) {
				m_trace->close();
				m_trace = NULL;
			}
		}

		virtual void tick() {
			if(m_clocks.size() == 0) {
				fprintf(stderr, "ERROR: Cannot run simulation with no clocks\n");
				exit(1);
			}

			uint64_t min_time = std::min_element(m_clocks.begin(), m_clocks.end())->time_to_edge();
			eval();
			for(auto&& clk : m_clocks) {
				auto inc = clk.advance(min_time);
				clk.set(inc);
			}

			m_time_ps += min_time;

			eval();

			if (m_trace) {
				m_trace->dump(m_time_ps);
				m_trace->flush();
			}

			m_uart_simulator->tick(m_core->o_tx, m_core->o_tx_stb, m_core->o_rx_stb, m_core->i_rx, m_core->i_rx_available);

			fflush(stdout);
		}

		virtual	void reset(int ticks) {
			m_core->i_rx = 1;
			m_core->i_reset = 1;
			for(int i = 0; i < ticks; i++) {
				tick();
			}
			m_core->i_reset = 0;
		}

		virtual void reset_ms(uint64_t ms) {
			assert(ms > 0);

			auto time_target = m_time_ps + (ms * 1'000'000'000ULL);

			m_core->i_reset = 1;
			while(m_time_ps < time_target) {
				tick();
			}
			m_core->i_reset = 0;
		}
};

#endif