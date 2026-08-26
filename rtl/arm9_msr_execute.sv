module arm9_msr_execute #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic [31:0]               instruction,
  input  arm9_arch_pkg::arm9_mode_e current_mode,
  input  logic [31:0]               register_operand_value,
  input  logic                      negative,
  input  logic                      zero,
  input  logic                      carry,
  input  logic                      overflow,
  output logic                      decode_match,
  output logic                      encoding_valid,
  output logic                      unpredictable_encoding,
  output logic                      condition_passed,
  output logic                      unconditional_space,
  output logic                      immediate_operand,
  output logic                      spsr_select,
  output logic [3:0]                field_mask,
  output logic [3:0]                source_register,
  output logic [31:0]               operand_value,
  output logic                      unpredictable_operation,
  output logic                      execute_valid,
  output logic                      cpsr_write_valid,
  output logic                      spsr_write_valid,
  output logic [31:0]               psr_write_data,
  output logic [31:0]               psr_write_mask,
  output logic                      flags_only_timing_class,
  output logic                      other_timing_class
);
  import arm9_arch_pkg::*;
  import arm9_psr_pkg::*;

  logic [3:0] decoded_condition;
  logic       decoded_mrs_operation;
  logic       decoded_msr_operation;
  logic [3:0] decoded_destination_register;
  logic [3:0] decoded_rotate_imm;
  logic [7:0] decoded_immediate_value;
  logic       condition_result;
  logic       condition_unconditional;
  logic [31:0] expanded_immediate;
  logic        expanded_carry;
  logic [31:0] byte_mask;
  logic [31:0] allowed_mask;
  logic [31:0] effective_mask;
  logic [31:0] unallocated_mask;
  logic [31:0] user_mask;
  logic        privileged_mode;
  logic        current_mode_has_spsr;
  logic        target_mode_valid;
  logic        active_operation;
  logic        reserved_bits_set;
  logic        cpsr_state_attempt;
  logic        invalid_mode_attempt;

  arm9_psr_transfer_decoder decoder (
    .instruction,
    .decode_match,
    .encoding_valid,
    .unpredictable_encoding,
    .condition(decoded_condition),
    .mrs_operation(decoded_mrs_operation),
    .msr_operation(decoded_msr_operation),
    .immediate_operand,
    .spsr_select,
    .field_mask,
    .destination_register(decoded_destination_register),
    .source_register,
    .rotate_imm(decoded_rotate_imm),
    .immediate_value(decoded_immediate_value)
  );

  arm9_condition_eval condition_evaluator (
    .condition(instruction[31:28]),
    .flag_n(negative),
    .flag_z(zero),
    .flag_c(carry),
    .flag_v(overflow),
    .condition_passed(condition_result),
    .unconditional_space(condition_unconditional)
  );

  arm9_immediate_expander immediate_expander (
    .immediate_value(decoded_immediate_value),
    .rotate_imm(decoded_rotate_imm),
    .carry_in(carry),
    .expanded_value(expanded_immediate),
    .carry_out(expanded_carry)
  );

  always_comb begin
    condition_passed = condition_result;
    unconditional_space = condition_unconditional;
    operand_value = immediate_operand ? expanded_immediate :
                    register_operand_value;

    byte_mask = {
      {8{field_mask[3]}},
      {8{field_mask[2]}},
      {8{field_mask[1]}},
      {8{field_mask[0]}}
    };
    unallocated_mask = msr_unallocated_mask(PROFILE);
    user_mask = msr_user_mask(PROFILE);
    privileged_mode = mode_is_privileged(current_mode);
    current_mode_has_spsr = mode_has_spsr(current_mode);
    target_mode_valid = mode_is_valid(arm9_mode_e'(operand_value[4:0]));

    if (spsr_select) begin
      allowed_mask = user_mask | msr_privileged_mask() |
                     msr_state_mask();
    end else if (privileged_mode) begin
      allowed_mask = user_mask | msr_privileged_mask();
    end else begin
      allowed_mask = user_mask;
    end
    effective_mask = byte_mask & allowed_mask;

    active_operation = encoding_valid && decoded_msr_operation &&
                       condition_result;
    reserved_bits_set = (operand_value & unallocated_mask) != 32'b0;
    cpsr_state_attempt = !spsr_select && privileged_mode &&
                         ((operand_value & msr_state_mask()) != 32'b0);
    invalid_mode_attempt = field_mask[0] && !target_mode_valid &&
                           (spsr_select ? current_mode_has_spsr :
                                          privileged_mode);
    unpredictable_operation = active_operation &&
      (reserved_bits_set ||
       (spsr_select && !current_mode_has_spsr) ||
       cpsr_state_attempt || invalid_mode_attempt);
    execute_valid = active_operation && !unpredictable_operation;

    psr_write_data = operand_value;
    psr_write_mask = execute_valid ? effective_mask : 32'b0;
    cpsr_write_valid = execute_valid && !spsr_select &&
                       (effective_mask != 32'b0);
    spsr_write_valid = execute_valid && spsr_select &&
                       (effective_mask != 32'b0);
    flags_only_timing_class = execute_valid && (field_mask == 4'b1000);
    other_timing_class = execute_valid && (field_mask != 4'b1000);
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(cpsr_write_valid && spsr_write_valid));
    assert (!(unpredictable_operation && execute_valid));
    assert (!(unpredictable_operation &&
              (!active_operation ||
               !(reserved_bits_set ||
                 (spsr_select && !current_mode_has_spsr) ||
                 cpsr_state_attempt || invalid_mode_attempt))));
    assert (!(execute_valid && !decoded_msr_operation));
    assert (!(cpsr_write_valid &&
              (!execute_valid || spsr_select ||
               (psr_write_mask == 32'b0))));
    assert (!(spsr_write_valid &&
              (!execute_valid || !spsr_select ||
               (psr_write_mask == 32'b0))));
    assert (!(flags_only_timing_class && other_timing_class));
    assert ((flags_only_timing_class || other_timing_class) ==
            execute_valid);
    assert ((psr_write_mask & ~allowed_mask) == 32'b0);
    assert ((psr_write_mask & ~byte_mask) == 32'b0);
    assert (!$isunknown(decoded_condition));
    assert (!$isunknown(decoded_destination_register));
    assert (!$isunknown(expanded_carry));
    assert (!(decoded_mrs_operation && decoded_msr_operation));
    if (decode_match) begin
      assert (decoded_condition == instruction[31:28]);
    end
    if (execute_valid && !spsr_select) begin
      assert ((psr_write_mask & msr_state_mask()) == 32'b0);
    end
  end
`endif
endmodule
