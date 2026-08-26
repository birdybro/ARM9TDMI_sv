module arm9_status_registers #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic                      clk,
  input  logic                      reset,
  input  logic                      cpsr_write_enable,
  input  logic [31:0]               cpsr_write_data,
  input  logic [31:0]               cpsr_write_mask,
  output logic [31:0]               cpsr_value,
  output arm9_arch_pkg::arm9_mode_e current_mode,
  input  arm9_arch_pkg::arm9_mode_e spsr_read_mode,
  output logic                      spsr_read_valid,
  output logic [31:0]               spsr_read_value,
  input  logic                      spsr_write_enable,
  input  arm9_arch_pkg::arm9_mode_e spsr_write_mode,
  input  logic [31:0]               spsr_write_data,
  input  logic [31:0]               spsr_write_mask
);
  import arm9_arch_pkg::*;
  import arm9_psr_pkg::*;

  logic [31:0] cpsr_storage;
  logic [31:0] spsr_fiq;
  logic [31:0] spsr_irq;
  logic [31:0] spsr_supervisor;
  logic [31:0] spsr_abort;
  logic [31:0] spsr_undefined;

  function automatic logic [31:0] selected_spsr(
    input arm9_mode_e mode
  );
    case (mode)
      ARM9_MODE_FIQ:        return spsr_fiq;
      ARM9_MODE_IRQ:        return spsr_irq;
      ARM9_MODE_SUPERVISOR: return spsr_supervisor;
      ARM9_MODE_ABORT:      return spsr_abort;
      ARM9_MODE_UNDEFINED:  return spsr_undefined;
      default:              return 'x;
    endcase
  endfunction

  always_comb begin
    cpsr_value      = psr_architectural_value(PROFILE, cpsr_storage);
    current_mode    = arm9_mode_e'(cpsr_storage[4:0]);
    spsr_read_valid = mode_has_spsr(spsr_read_mode);
    spsr_read_value = psr_architectural_value(
      PROFILE,
      selected_spsr(spsr_read_mode)
    );
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      // Reset constrains only M[4:0], T, F, and I. In particular, NZCV and
      // ARM9E-S Q remain architecturally indeterminate after reset.
      cpsr_storage[7:0] <= {
        1'b1,
        1'b1,
        1'b0,
        ARM9_MODE_SUPERVISOR
      };
    end else if (cpsr_write_enable) begin
      cpsr_storage <= psr_merge_write(
        PROFILE,
        cpsr_storage,
        cpsr_write_data,
        cpsr_write_mask
      );
    end

    if (!reset && spsr_write_enable) begin
      case (spsr_write_mode)
        ARM9_MODE_FIQ: begin
          spsr_fiq <= psr_merge_write(
            PROFILE,
            spsr_fiq,
            spsr_write_data,
            spsr_write_mask
          );
        end
        ARM9_MODE_IRQ: begin
          spsr_irq <= psr_merge_write(
            PROFILE,
            spsr_irq,
            spsr_write_data,
            spsr_write_mask
          );
        end
        ARM9_MODE_SUPERVISOR: begin
          spsr_supervisor <= psr_merge_write(
            PROFILE,
            spsr_supervisor,
            spsr_write_data,
            spsr_write_mask
          );
        end
        ARM9_MODE_ABORT: begin
          spsr_abort <= psr_merge_write(
            PROFILE,
            spsr_abort,
            spsr_write_data,
            spsr_write_mask
          );
        end
        ARM9_MODE_UNDEFINED: begin
          spsr_undefined <= psr_merge_write(
            PROFILE,
            spsr_undefined,
            spsr_write_data,
            spsr_write_mask
          );
        end
        default: begin
        end
      endcase
    end
  end

`ifndef SYNTHESIS
  always_ff @(posedge clk) begin
    if (!reset) begin
      assert (mode_is_valid(current_mode));
    end
    if (!reset && spsr_write_enable) begin
      assert (mode_has_spsr(spsr_write_mode));
    end
  end
`endif
endmodule
