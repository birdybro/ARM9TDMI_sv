package arm9_psr_pkg;
  import arm9_profile_pkg::*;

  localparam logic [31:0] ARM9_PSR_NZCV_MASK    = 32'hf000_0000;
  localparam logic [31:0] ARM9_PSR_Q_MASK       = 32'h0800_0000;
  localparam logic [31:0] ARM9_PSR_CONTROL_MASK = 32'h0000_00ff;

  function automatic logic [31:0] psr_implemented_mask(
    input arm9_profile_e profile
  );
    case (profile)
      ARM9_PROFILE_ARM9TDMI: begin
        return ARM9_PSR_NZCV_MASK | ARM9_PSR_CONTROL_MASK;
      end
      ARM9_PROFILE_ARM946ES: begin
        return ARM9_PSR_NZCV_MASK | ARM9_PSR_Q_MASK |
               ARM9_PSR_CONTROL_MASK;
      end
      default: return '0;
    endcase
  endfunction

  function automatic logic [31:0] psr_architectural_value(
    input arm9_profile_e profile,
    input logic [31:0] storage_value
  );
    return storage_value & psr_implemented_mask(profile);
  endfunction

  function automatic logic [31:0] psr_merge_write(
    input arm9_profile_e profile,
    input logic [31:0] current_value,
    input logic [31:0] write_value,
    input logic [31:0] write_mask
  );
    logic [31:0] effective_mask;

    effective_mask = write_mask & psr_implemented_mask(profile);
    return (current_value & ~effective_mask) |
           (write_value & effective_mask);
  endfunction
endpackage
