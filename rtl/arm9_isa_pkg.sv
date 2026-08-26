package arm9_isa_pkg;
  typedef enum logic [1:0] {
    ARM9_SHIFT_LSL = 2'b00,
    ARM9_SHIFT_LSR = 2'b01,
    ARM9_SHIFT_ASR = 2'b10,
    ARM9_SHIFT_ROR = 2'b11
  } arm9_shift_type_e;
endpackage
