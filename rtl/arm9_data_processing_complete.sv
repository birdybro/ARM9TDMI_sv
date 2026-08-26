module arm9_data_processing_complete (
  input  logic                      result_write_pending,
  input  logic                      flags_write_pending,
  input  logic [3:0]                destination_register,
  input  logic [31:0]               result_value,
  input  logic                      negative_value,
  input  logic                      zero_value,
  input  logic                      carry_value,
  input  logic                      overflow_value,
  input  arm9_arch_pkg::arm9_mode_e current_mode,
  input  logic [31:0]               current_spsr_value,
  output logic                      pc_destination,
  output logic                      unpredictable_operation,
  output logic                      register_write_valid,
  output logic [3:0]                register_write_register,
  output logic [31:0]               register_write_value,
  output logic                      nzcv_write_valid,
  output logic                      negative_write_value,
  output logic                      zero_write_value,
  output logic                      carry_write_value,
  output logic                      overflow_write_value,
  output logic                      pc_write_valid,
  output logic [31:0]               pc_write_value,
  output logic                      pc_write_thumb_state,
  output logic                      cpsr_restore_valid,
  output logic [31:0]               cpsr_restore_value,
  output logic                      pipeline_flush_request
);
  import arm9_arch_pkg::*;

  logic        pc_write_pending;
  logic        exception_return_pending;
  logic        current_mode_has_spsr;
  logic        target_thumb_state;
  logic [31:0] unused_pc_read_value;
  logic [31:0] aligned_pc_target;
  logic        aligned_pc_thumb_state;
  logic        unpredictable_alignment;

  arm9_pc_addressing pc_addressing (
    .instruction_address(32'b0),
    .thumb_state(target_thumb_state),
    .write_value(result_value),
    .exchange_state(1'b0),
    .pc_read_value(unused_pc_read_value),
    .write_target(aligned_pc_target),
    .write_thumb_state(aligned_pc_thumb_state),
    .unpredictable_alignment
  );

  always_comb begin
    pc_destination = destination_register == 4'hf;
    pc_write_pending = result_write_pending && pc_destination;
    exception_return_pending = pc_write_pending && flags_write_pending;
    current_mode_has_spsr = mode_has_spsr(current_mode);
    target_thumb_state = exception_return_pending &&
                         current_mode_has_spsr &&
                         current_spsr_value[5];

    unpredictable_operation = pc_write_pending &&
      ((exception_return_pending && !current_mode_has_spsr) ||
       unpredictable_alignment);

    register_write_valid = result_write_pending && !pc_destination;
    register_write_register = destination_register;
    register_write_value = result_value;

    nzcv_write_valid = flags_write_pending && !pc_destination;
    negative_write_value = negative_value;
    zero_write_value = zero_value;
    carry_write_value = carry_value;
    overflow_write_value = overflow_value;

    pc_write_valid = pc_write_pending && !unpredictable_operation;
    pc_write_value = aligned_pc_target;
    pc_write_thumb_state = aligned_pc_thumb_state;
    cpsr_restore_valid = pc_write_valid && exception_return_pending;
    cpsr_restore_value = current_spsr_value;
    pipeline_flush_request = pc_write_valid;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (mode_is_valid(current_mode));
    assert (!(register_write_valid && pc_destination));
    assert (!(nzcv_write_valid && pc_destination));
    assert (!(pc_write_valid && !pc_destination));
    assert (!(cpsr_restore_valid &&
              (!pc_write_valid || !flags_write_pending ||
               !current_mode_has_spsr)));
    assert (!(unpredictable_operation &&
              (pc_write_valid || cpsr_restore_valid ||
               pipeline_flush_request)));
    assert (pipeline_flush_request == pc_write_valid);
    if (pc_write_valid) begin
      assert (pc_write_thumb_state == target_thumb_state);
      if (pc_write_thumb_state) begin
        assert (pc_write_value[0] == 1'b0);
      end else begin
        assert (pc_write_value[1:0] == 2'b00);
      end
    end
  end
`endif
endmodule
