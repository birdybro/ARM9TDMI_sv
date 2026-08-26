module arm9_saturating_execute #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic [31:0]                           instruction,
  input  logic [31:0]                           first_operand_value,
  input  logic [31:0]                           second_operand_value,
  input  logic                                  q_in,
  input  logic                                  negative_in,
  input  logic                                  zero_in,
  input  logic                                  carry_in,
  input  logic                                  overflow_in,
  output logic                                  decode_match,
  output logic                                  profile_legal,
  output logic                                  profile_illegal_encoding,
  output logic                                  encoding_valid,
  output logic                                  unpredictable_encoding,
  output logic                                  condition_passed,
  output logic                                  unconditional_space,
  output logic                                  execute_valid,
  output arm9_isa_pkg::arm9_saturating_kind_e  saturating_kind,
  output logic [3:0]                            destination_register,
  output logic [3:0]                            first_operand_register,
  output logic [3:0]                            second_operand_register,
  output logic                                  destination_write_enable,
  output logic [31:0]                           destination_write_data,
  output logic                                  q_set_request,
  output logic                                  q_out,
  output logic                                  nzcv_write_enable,
  output logic                                  negative_out,
  output logic                                  zero_out,
  output logic                                  carry_out,
  output logic                                  overflow_out
);
  logic [3:0] decoded_condition;
  logic condition_result;
  logic condition_unconditional;
  logic alu_q_set;
  logic alu_q_out;

  arm9_saturating_decoder #(
    .PROFILE(PROFILE)
  ) decoder (
    .instruction,
    .decode_match,
    .profile_legal,
    .profile_illegal_encoding,
    .encoding_valid,
    .unpredictable_encoding,
    .condition(decoded_condition),
    .saturating_kind,
    .destination_register,
    .first_operand_register,
    .second_operand_register
  );

  arm9_condition_eval condition_evaluator (
    .condition(instruction[31:28]),
    .flag_n(negative_in),
    .flag_z(zero_in),
    .flag_c(carry_in),
    .flag_v(overflow_in),
    .condition_passed(condition_result),
    .unconditional_space(condition_unconditional)
  );

  arm9e_saturating_alu alu (
    .saturating_kind,
    .first_operand(first_operand_value),
    .second_operand(second_operand_value),
    .q_in,
    .negative_in,
    .zero_in,
    .carry_in,
    .overflow_in,
    .result(destination_write_data),
    .q_set(alu_q_set),
    .q_out(alu_q_out),
    .negative_out,
    .zero_out,
    .carry_out,
    .overflow_out
  );

  always_comb begin
    condition_passed    = condition_result;
    unconditional_space = condition_unconditional;
    execute_valid = encoding_valid && condition_result;
    destination_write_enable = execute_valid;
    q_set_request = execute_valid && alu_q_set;
    q_out = q_in || q_set_request;
    nzcv_write_enable = 1'b0;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(execute_valid && (!encoding_valid || !condition_passed)));
    assert (!(destination_write_enable && !execute_valid));
    assert (!(q_set_request && !execute_valid));
    assert (!(profile_illegal_encoding && execute_valid));
    assert (!nzcv_write_enable);
    assert (alu_q_out == (q_in || alu_q_set));
    if (decode_match) begin
      assert (decoded_condition == instruction[31:28]);
    end
  end
`endif
endmodule
