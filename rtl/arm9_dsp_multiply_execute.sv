module arm9_dsp_multiply_execute #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic [31:0] instruction,
  input  logic [31:0] multiplicand_value,
  input  logic [31:0] multiplier_value,
  input  logic [31:0] accumulator_low_value,
  input  logic [31:0] accumulator_high_value,
  input  logic        q_in,
  input  logic        negative_in,
  input  logic        zero_in,
  input  logic        carry_in,
  input  logic        overflow_in,
  output logic        decode_match,
  output logic        profile_legal,
  output logic        profile_illegal_encoding,
  output logic        encoding_valid,
  output logic        unpredictable_encoding,
  output logic        condition_passed,
  output logic        unconditional_space,
  output logic        execute_valid,
  output arm9_isa_pkg::arm9_dsp_multiply_kind_e dsp_multiply_kind,
  output arm9_isa_pkg::arm9_multiply_kind_e timing_kind,
  output logic [3:0]  destination_high_register,
  output logic [3:0]  accumulator_or_low_register,
  output logic [3:0]  multiplier_register,
  output logic [3:0]  multiplicand_register,
  output logic        long_result,
  output logic        destination_high_write_enable,
  output logic [31:0] destination_high_write_data,
  output logic        destination_low_write_enable,
  output logic [31:0] destination_low_write_data,
  output logic        q_set_request,
  output logic        q_out,
  output logic        negative_out,
  output logic        zero_out,
  output logic        carry_out,
  output logic        overflow_out
);
  logic [3:0] decoded_condition;
  logic x_bit;
  logic y_bit;
  logic condition_result;
  logic condition_unconditional;
  logic operation_supported;
  logic alu_accumulate;
  logic [31:0] result_low;
  logic [31:0] result_high;
  logic alu_q_set;
  logic alu_q_out;

  arm9_dsp_multiply_decoder #(
    .PROFILE(PROFILE)
  ) decoder (
    .instruction,
    .decode_match,
    .profile_legal,
    .profile_illegal_encoding,
    .encoding_valid,
    .unpredictable_encoding,
    .condition(decoded_condition),
    .dsp_multiply_kind,
    .timing_kind,
    .x_bit,
    .y_bit,
    .destination_high_register,
    .accumulator_or_low_register,
    .multiplier_register,
    .multiplicand_register
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

  arm9e_dsp_multiply_alu alu (
    .dsp_multiply_kind,
    .x_bit,
    .y_bit,
    .multiplicand_value,
    .multiplier_value,
    .accumulator_low_value,
    .accumulator_high_value,
    .q_in,
    .negative_in,
    .zero_in,
    .carry_in,
    .overflow_in,
    .operation_supported,
    .long_result,
    .accumulate(alu_accumulate),
    .result_low,
    .result_high,
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
    execute_valid = encoding_valid && condition_result &&
                    operation_supported;

    destination_high_write_enable = execute_valid;
    destination_low_write_enable  = execute_valid && long_result;
    destination_high_write_data   = long_result ? result_high : result_low;
    destination_low_write_data    = result_low;
    q_set_request = execute_valid && alu_q_set;
    q_out         = q_in || q_set_request;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(execute_valid && (!encoding_valid || !profile_legal)));
    assert (!(destination_high_write_enable && !execute_valid));
    assert (!(destination_low_write_enable &&
              (!execute_valid || !long_result)));
    assert (!(q_set_request && !execute_valid));
    assert (!(profile_illegal_encoding && execute_valid));
    assert (alu_q_out == (q_in || alu_q_set));
    if (decode_match) begin
      assert (decoded_condition == instruction[31:28]);
      assert (alu_accumulate ==
              ((dsp_multiply_kind ==
                arm9_isa_pkg::ARM9_DSP_MULTIPLY_SMLA_XY) ||
               (dsp_multiply_kind ==
                arm9_isa_pkg::ARM9_DSP_MULTIPLY_SMLAW_Y) ||
               (dsp_multiply_kind ==
                arm9_isa_pkg::ARM9_DSP_MULTIPLY_SMLAL_XY)));
    end
  end
`endif
endmodule
