module arm9_mrs_execute (
  input  logic [31:0]               instruction,
  input  arm9_arch_pkg::arm9_mode_e current_mode,
  input  logic [31:0]               cpsr_value,
  input  logic [31:0]               current_spsr_value,
  input  logic                      negative,
  input  logic                      zero,
  input  logic                      carry,
  input  logic                      overflow,
  output logic                      decode_match,
  output logic                      encoding_valid,
  output logic                      unpredictable_encoding,
  output logic                      condition_passed,
  output logic                      unconditional_space,
  output logic                      spsr_select,
  output logic                      unpredictable_operation,
  output logic                      execute_valid,
  output logic                      destination_write_valid,
  output logic [3:0]                destination_write_register,
  output logic [31:0]               destination_write_value
);
  logic       decoded_mrs_operation;
  logic       decoded_msr_operation;
  logic       decoded_immediate_operand;
  logic [3:0] decoded_condition;
  logic [3:0] decoded_field_mask;
  logic [3:0] decoded_source_register;
  logic [3:0] decoded_rotate_imm;
  logic [7:0] decoded_immediate_value;
  logic       condition_result;
  logic       condition_unconditional;

  arm9_psr_transfer_decoder decoder (
    .instruction,
    .decode_match,
    .encoding_valid,
    .unpredictable_encoding,
    .condition(decoded_condition),
    .mrs_operation(decoded_mrs_operation),
    .msr_operation(decoded_msr_operation),
    .immediate_operand(decoded_immediate_operand),
    .spsr_select,
    .field_mask(decoded_field_mask),
    .destination_register(destination_write_register),
    .source_register(decoded_source_register),
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

  always_comb begin
    condition_passed = condition_result;
    unconditional_space = condition_unconditional;
    unpredictable_operation = encoding_valid && decoded_mrs_operation &&
                              condition_result && spsr_select &&
                              !arm9_arch_pkg::mode_has_spsr(current_mode);
    execute_valid = encoding_valid && decoded_mrs_operation &&
                    condition_result && !unpredictable_operation;
    destination_write_valid = execute_valid;
    destination_write_value = spsr_select ? current_spsr_value : cpsr_value;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(unpredictable_operation &&
              (!encoding_valid || !decoded_mrs_operation ||
               !condition_passed || !spsr_select ||
               arm9_arch_pkg::mode_has_spsr(current_mode))));
    assert (destination_write_valid == execute_valid);
    assert (!(destination_write_valid &&
              (destination_write_register == 4'hf)));
    assert (!$isunknown(decoded_immediate_operand));
    assert (!$isunknown(decoded_field_mask));
    assert (!$isunknown(decoded_source_register));
    assert (!$isunknown(decoded_rotate_imm));
    assert (!$isunknown(decoded_immediate_value));
    if (decode_match && decoded_mrs_operation) begin
      assert (decoded_condition == instruction[31:28]);
    end
    assert (!(decoded_mrs_operation && decoded_msr_operation));
  end
`endif
endmodule
