module arm9_block_pc_complete #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic        completion_valid,
  input  logic        precise_data_abort,
  input  logic        pc_load_pending,
  input  logic        restore_cpsr_pending,
  input  logic [31:0] loaded_pc_value,
  input  logic        spsr_thumb_state,
  input  logic        arm946_disable_loading_tbit,
  output logic        data_abort_taken,
  output logic        pc_write_valid,
  output logic [31:0] pc_write_value,
  output logic        pc_write_thumb_state,
  output logic        cpsr_restore_valid,
  output logic        pc_state_from_spsr,
  output logic        pc_load_tbit_enabled,
  output logic        unpredictable_result
);
  import arm9_profile_pkg::*;

  logic successful_pc_completion;

  always_comb begin
    data_abort_taken = completion_valid && precise_data_abort;
    successful_pc_completion = completion_valid && !precise_data_abort &&
                               pc_load_pending;
    pc_state_from_spsr = restore_cpsr_pending;
    pc_load_tbit_enabled = !restore_cpsr_pending &&
                           (PROFILE == ARM9_PROFILE_ARM946ES) &&
                           !arm946_disable_loading_tbit;

    unpredictable_result = successful_pc_completion &&
                           pc_load_tbit_enabled &&
                           (loaded_pc_value[1:0] == 2'b10);
    pc_write_valid = successful_pc_completion && !unpredictable_result;
    cpsr_restore_valid = pc_write_valid && restore_cpsr_pending;

    if (restore_cpsr_pending) begin
      pc_write_thumb_state = spsr_thumb_state;
      if (spsr_thumb_state) begin
        pc_write_value = {loaded_pc_value[31:1], 1'b0};
      end else begin
        pc_write_value = {loaded_pc_value[31:2], 2'b00};
      end
    end else if (pc_load_tbit_enabled) begin
      pc_write_value = {loaded_pc_value[31:1], 1'b0};
      pc_write_thumb_state = loaded_pc_value[0];
    end else begin
      pc_write_value = {loaded_pc_value[31:2], 2'b00};
      pc_write_thumb_state = 1'b0;
    end
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!restore_cpsr_pending || pc_load_pending);
    assert (!(data_abort_taken &&
              (pc_write_valid || cpsr_restore_valid)));
    assert (!(cpsr_restore_valid &&
              (!pc_write_valid || !restore_cpsr_pending)));
    assert (!(pc_load_tbit_enabled &&
              ((PROFILE != ARM9_PROFILE_ARM946ES) ||
               arm946_disable_loading_tbit || restore_cpsr_pending)));
    assert (!(unpredictable_result &&
              (!successful_pc_completion || !pc_load_tbit_enabled ||
               (loaded_pc_value[1:0] != 2'b10))));
    assert (!(unpredictable_result &&
              (pc_write_valid || cpsr_restore_valid)));
    if (restore_cpsr_pending) begin
      assert (pc_write_thumb_state == spsr_thumb_state);
    end
    if (pc_write_valid) begin
      if (pc_write_thumb_state) begin
        assert (pc_write_value[0] == 1'b0);
      end else begin
        assert (pc_write_value[1:0] == 2'b00);
      end
    end
  end
`endif
endmodule
