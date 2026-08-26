module arm9_data_processing_execute (
  input  logic [31:0] instruction,
  input  logic [31:0] first_operand_value,
  input  logic [31:0] shifted_register_value,
  input  logic [7:0]  shift_register_value,
  input  logic        negative_in,
  input  logic        zero_in,
  input  logic        carry_in,
  input  logic        overflow_in,
  output logic        decode_match,
  output logic        encoding_valid,
  output logic        unpredictable_encoding,
  output logic        condition_passed,
  output logic        unconditional_space,
  output logic        execute_valid,
  output logic [3:0]  first_register,
  output logic [3:0]  destination_register,
  output logic [3:0]  shift_register,
  output logic [3:0]  shifted_register,
  output logic [31:0] result,
  output logic        result_write_enable,
  output logic        flags_write_enable,
  output logic        negative_out,
  output logic        zero_out,
  output logic        carry_out,
  output logic        overflow_out
);
  import arm9_isa_pkg::*;

  logic [3:0]       condition;
  logic             immediate_operand;
  arm9_data_opcode_e opcode;
  logic             set_flags;
  logic [7:0]       immediate_value;
  logic [3:0]       rotate_imm;
  logic [4:0]       immediate_shift_amount;
  arm9_shift_type_e shift_type;
  logic             shift_amount_from_register;
  logic [7:0]       selected_shift_amount;
  logic [31:0]      register_shifter_result;
  logic             register_shifter_carry;
  logic [31:0]      immediate_result;
  logic             immediate_carry;
  logic [31:0]      selected_shifter_operand;
  logic             selected_shifter_carry;
  logic             alu_writes_result;

  arm9_data_processing_decoder decoder (
    .instruction,
    .decode_match,
    .encoding_valid,
    .unpredictable_encoding,
    .condition,
    .immediate_operand,
    .opcode,
    .set_flags,
    .first_register,
    .destination_register,
    .immediate_value,
    .rotate_imm,
    .shift_register,
    .immediate_shift_amount,
    .shift_type,
    .shift_amount_from_register,
    .shifted_register
  );

  arm9_condition_eval condition_evaluator (
    .condition,
    .flag_n(negative_in),
    .flag_z(zero_in),
    .flag_c(carry_in),
    .flag_v(overflow_in),
    .condition_passed,
    .unconditional_space
  );

  always_comb begin
    if (shift_amount_from_register) begin
      selected_shift_amount = shift_register_value;
    end else begin
      selected_shift_amount = {3'b000, immediate_shift_amount};
    end

    if (immediate_operand) begin
      selected_shifter_operand = immediate_result;
      selected_shifter_carry   = immediate_carry;
    end else begin
      selected_shifter_operand = register_shifter_result;
      selected_shifter_carry   = register_shifter_carry;
    end

    execute_valid       = encoding_valid && condition_passed;
    result_write_enable = execute_valid && alu_writes_result;
    flags_write_enable  = execute_valid && set_flags;
  end

  arm9_barrel_shifter register_shifter (
    .value(shifted_register_value),
    .shift_type,
    .shift_amount(selected_shift_amount),
    .amount_from_register(shift_amount_from_register),
    .carry_in,
    .result(register_shifter_result),
    .carry_out(register_shifter_carry)
  );

  arm9_immediate_expander immediate_expander (
    .immediate_value,
    .rotate_imm,
    .carry_in,
    .expanded_value(immediate_result),
    .carry_out(immediate_carry)
  );

  arm9_data_alu alu (
    .opcode,
    .first_operand(first_operand_value),
    .shifter_operand(selected_shifter_operand),
    .carry_in,
    .overflow_in,
    .shifter_carry_out(selected_shifter_carry),
    .result,
    .writes_result(alu_writes_result),
    .negative_out,
    .zero_out,
    .carry_out,
    .overflow_out
  );

`ifndef SYNTHESIS
  always_comb begin
    assert (!(result_write_enable && !execute_valid));
    assert (!(flags_write_enable && !execute_valid));
  end
`endif
endmodule
