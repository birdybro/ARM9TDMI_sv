package arm9_timing_pkg;
  typedef enum logic [2:0] {
    ARM9_BUS_CYCLE_UNSPECIFIED,
    ARM9_BUS_CYCLE_INTERNAL,
    ARM9_BUS_CYCLE_NONSEQUENTIAL,
    ARM9_BUS_CYCLE_SEQUENTIAL,
    ARM9_BUS_CYCLE_COPROCESSOR
  } arm9_bus_cycle_e;
endpackage
