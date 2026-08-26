module arm9_exception_entry #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic                                exception_valid,
  input  arm9_arch_pkg::arm9_exception_kind_e exception_kind,
  input  logic [31:0]                         current_cpsr,
  input  logic [31:0]                         instruction_address,
  input  logic [31:0]                         next_instruction_address,
  input  logic                                arm9tdmi_hivecs,
  input  logic                                arm946_cp15_high_vectors,
  output logic                                high_vectors_selected,
  output arm9_arch_pkg::arm9_mode_e            exception_mode,
  output logic [4:0]                          vector_offset,
  output logic [31:0]                         vector_address,
  output logic                                link_write_valid,
  output arm9_arch_pkg::arm9_mode_e            link_write_mode,
  output logic [31:0]                         link_write_value,
  output logic                                link_value_unpredictable,
  output logic                                spsr_write_valid,
  output arm9_arch_pkg::arm9_mode_e            spsr_write_mode,
  output logic [31:0]                         spsr_write_value,
  output logic                                spsr_value_unpredictable,
  output logic                                cpsr_write_valid,
  output logic [31:0]                         cpsr_write_value,
  output logic [31:0]                         cpsr_write_mask,
  output logic                                pipeline_flush
);
  import arm9_profile_pkg::*;
  import arm9_arch_pkg::*;

  always_comb begin
    high_vectors_selected = (PROFILE == ARM9_PROFILE_ARM9TDMI) ?
                            arm9tdmi_hivecs :
                            arm946_cp15_high_vectors;

    exception_mode = ARM9_MODE_SUPERVISOR;
    vector_offset = 5'h00;
    link_write_value = 32'b0;
    case (exception_kind)
      ARM9_EXCEPTION_RESET: begin
        exception_mode = ARM9_MODE_SUPERVISOR;
        vector_offset = 5'h00;
      end
      ARM9_EXCEPTION_UNDEFINED: begin
        exception_mode = ARM9_MODE_UNDEFINED;
        vector_offset = 5'h04;
        link_write_value = next_instruction_address;
      end
      ARM9_EXCEPTION_SWI: begin
        exception_mode = ARM9_MODE_SUPERVISOR;
        vector_offset = 5'h08;
        link_write_value = next_instruction_address;
      end
      ARM9_EXCEPTION_PREFETCH_ABORT: begin
        exception_mode = ARM9_MODE_ABORT;
        vector_offset = 5'h0c;
        link_write_value = instruction_address + 32'd4;
      end
      ARM9_EXCEPTION_DATA_ABORT: begin
        exception_mode = ARM9_MODE_ABORT;
        vector_offset = 5'h10;
        link_write_value = instruction_address + 32'd8;
      end
      ARM9_EXCEPTION_IRQ: begin
        exception_mode = ARM9_MODE_IRQ;
        vector_offset = 5'h18;
        link_write_value = next_instruction_address + 32'd4;
      end
      ARM9_EXCEPTION_FIQ: begin
        exception_mode = ARM9_MODE_FIQ;
        vector_offset = 5'h1c;
        link_write_value = next_instruction_address + 32'd4;
      end
      default: begin
        exception_mode = ARM9_MODE_SUPERVISOR;
        vector_offset = 5'h00;
        link_write_value = 32'b0;
      end
    endcase

    vector_address = (high_vectors_selected ? 32'hffff_0000 : 32'b0) |
                     {27'b0, vector_offset};

    link_write_valid = exception_valid &&
                       (exception_kind != ARM9_EXCEPTION_RESET);
    link_write_mode = exception_mode;
    link_value_unpredictable = exception_valid &&
                               (exception_kind == ARM9_EXCEPTION_RESET);

    spsr_write_valid = exception_valid &&
                       (exception_kind != ARM9_EXCEPTION_RESET);
    spsr_write_mode = exception_mode;
    spsr_write_value = current_cpsr;
    spsr_value_unpredictable = exception_valid &&
                               (exception_kind == ARM9_EXCEPTION_RESET);

    cpsr_write_valid = exception_valid;
    cpsr_write_value = current_cpsr;
    cpsr_write_value[4:0] = exception_mode;
    cpsr_write_value[5] = 1'b0;
    cpsr_write_value[7] = 1'b1;
    if ((exception_kind == ARM9_EXCEPTION_RESET) ||
        (exception_kind == ARM9_EXCEPTION_FIQ)) begin
      cpsr_write_value[6] = 1'b1;
    end
    cpsr_write_mask = 32'h0000_00ff;
    pipeline_flush = exception_valid;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (arm9_arch_pkg::mode_has_spsr(exception_mode));
    assert (link_write_mode == exception_mode);
    assert (spsr_write_mode == exception_mode);
    assert (vector_address[4:0] == vector_offset);
    assert (vector_address[15:5] == 11'b0);
    assert (vector_address[31:16] ==
            (high_vectors_selected ? 16'hffff : 16'h0000));
    assert (cpsr_write_mask == 32'h0000_00ff);
    assert (cpsr_write_value[4:0] == exception_mode);
    assert (!cpsr_write_value[5]);
    assert (cpsr_write_value[7]);
    assert (cpsr_write_value[31:8] == current_cpsr[31:8]);
    assert (!(link_write_valid && link_value_unpredictable));
    assert (!(spsr_write_valid && spsr_value_unpredictable));
    if (exception_valid) begin
      assert (cpsr_write_valid && pipeline_flush);
      if ((exception_kind == ARM9_EXCEPTION_RESET) ||
          (exception_kind == ARM9_EXCEPTION_FIQ)) begin
        assert (cpsr_write_value[6]);
      end else begin
        assert (cpsr_write_value[6] == current_cpsr[6]);
      end
    end
  end
`endif
endmodule
