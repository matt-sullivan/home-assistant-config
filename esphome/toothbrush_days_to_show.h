#pragma once
#include <vector>

struct DayToShow {
  char day[3];
  float am;
  float pm;
};

typedef enum {
  Mode_Init,       // after reboot, before sensor values received
  Mode_Welcome,    // idle "Hello Toby" screen
  Mode_Brushing,   // active brushing display
  Mode_StatsPeek,  // temporary stats peek (5 s, then returns to peek_return_mode)
  Mode_Stats,      // post-brush stats (60 s, then Off)
  Mode_Off,        // screen off
} DisplayMode;

const int TargetDuration = 120;

// Global variable
std::vector<DayToShow> stats;
