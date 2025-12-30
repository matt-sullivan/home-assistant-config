#pragma once
#include <vector>

struct DayToShow {
  char day[3];
  float am;
  float pm;
};

typedef enum {Mode_Welcome, Mode_Brushing, Mode_Stats, Mode_Off} DisplayMode;

const int TargetDuration = 120;

// Global variable
std::vector<DayToShow> stats;
