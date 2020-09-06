#pragma once
#ifndef __SIMLOG_HPP
#define __SIMLOG_HPP 1

#define LOG_INFO(...)  do { fprintf(stderr, "INFO:    "); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } while(0)
#define LOG_WARN(...)  do { fprintf(stderr, "WARNING: "); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } while(0)
#define LOG_ERROR(...) do { fprintf(stderr, "ERROR:   "); fprintf(stderr, __VA_ARGS__); fprintf(stderr, "\n"); } while(0)

#endif