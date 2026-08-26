package arm9_arch_pkg;
  typedef enum logic [4:0] {
    ARM9_MODE_USER       = 5'b10000,
    ARM9_MODE_FIQ        = 5'b10001,
    ARM9_MODE_IRQ        = 5'b10010,
    ARM9_MODE_SUPERVISOR = 5'b10011,
    ARM9_MODE_ABORT      = 5'b10111,
    ARM9_MODE_UNDEFINED  = 5'b11011,
    ARM9_MODE_SYSTEM     = 5'b11111
  } arm9_mode_e;

  function automatic logic mode_is_valid(input arm9_mode_e mode);
    case (mode)
      ARM9_MODE_USER,
      ARM9_MODE_FIQ,
      ARM9_MODE_IRQ,
      ARM9_MODE_SUPERVISOR,
      ARM9_MODE_ABORT,
      ARM9_MODE_UNDEFINED,
      ARM9_MODE_SYSTEM: return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  function automatic logic mode_is_privileged(input arm9_mode_e mode);
    return mode_is_valid(mode) && (mode != ARM9_MODE_USER);
  endfunction

  function automatic logic mode_has_spsr(input arm9_mode_e mode);
    case (mode)
      ARM9_MODE_FIQ,
      ARM9_MODE_IRQ,
      ARM9_MODE_SUPERVISOR,
      ARM9_MODE_ABORT,
      ARM9_MODE_UNDEFINED: return 1'b1;
      default: return 1'b0;
    endcase
  endfunction
endpackage
