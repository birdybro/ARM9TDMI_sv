module arm9_common_multiply_execute #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic [31:0] instruction,
  input  logic [31:0] multiplicand_value,
  input  logic [31:0] multiplier_value,
  input  logic [31:0] accumulator_low_value,
  input  logic [31:0] accumulator_high_value,
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
  output arm9_isa_pkg::arm9_multiply_kind_e multiply_kind,
  output logic [3:0]  destination_high_register,
  output logic [3:0]  destination_low_register,
  output logic [3:0]  multiplier_register,
  output logic [3:0]  multiplicand_register,
  output logic        long_result,
  output logic        destination_high_write_enable,
  output logic [31:0] destination_high_write_data,
  output logic        destination_low_write_enable,
  output logic [31:0] destination_low_write_data,
  output logic        flags_write_enable,
  output logic        negative_out,
  output logic        zero_out,
  output logic        carry_out,
  output logic        overflow_out,
  output logic        carry_unpredictable,
  output logic        overflow_unpredictable
);
  logic condition_result;
  logic condition_unconditional;
  logic [3:0] decoded_condition;
  logic set_flags;
  logic decoder_long_multiply;
  logic decoder_accumulate;
  logic decoder_signed_multiply;
  logic operation_supported;
  logic alu_accumulate;
  logic [31:0] result_low;
  logic [31:0] result_high;
  logic alu_flags_write_enable;
  logic alu_carry_unpredictable;
  logic alu_overflow_unpredictable;

  arm9_multiply_decoder decoder (
    .instruction,
    .decode_match,
    .encoding_valid,
    .unpredictable_encoding,
    .condition(decoded_condition),
    .multiply_kind,
    .set_flags,
    .long_multiply(decoder_long_multiply),
    .accumulate(decoder_accumulate),
    .signed_multiply(decoder_signed_multiply),
    .destination_high_register,
    .destination_low_register,
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

  arm9_common_multiply_alu #(
    .PROFILE(PROFILE)
  ) alu (
    .multiply_kind,
    .multiplicand_value,
    .multiplier_value,
    .accumulator_low_value,
    .accumulator_high_value,
    .set_flags,
    .negative_in,
    .zero_in,
    .carry_in,
    .overflow_in,
    .operation_supported,
    .long_result,
    .accumulate(alu_accumulate),
    .result_low,
    .result_high,
    .flags_write_enable(alu_flags_write_enable),
    .negative_out,
    .zero_out,
    .carry_out,
    .overflow_out,
    .carry_unpredictable(alu_carry_unpredictable),
    .overflow_unpredictable(alu_overflow_unpredictable)
  );

  always_comb begin
    condition_passed   = condition_result;
    unconditional_space = condition_unconditional;
    execute_valid = encoding_valid && condition_result &&
                    operation_supported;

    destination_high_write_enable = execute_valid;
    destination_low_write_enable  = execute_valid && long_result;
    destination_high_write_data   = long_result ? result_high : result_low;
    destination_low_write_data    = result_low;
    flags_write_enable = execute_valid && alu_flags_write_enable;
    carry_unpredictable = execute_valid && alu_carry_unpredictable;
    overflow_unpredictable = execute_valid && alu_overflow_unpredictable;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(execute_valid && !encoding_valid));
    assert (!(destination_high_write_enable && !execute_valid));
    assert (!(destination_low_write_enable &&
              (!execute_valid || !long_result)));
    assert (!(flags_write_enable && !execute_valid));
    assert (!(carry_unpredictable && !execute_valid));
    if (decode_match) begin
      assert (decoded_condition == instruction[31:28]);
      assert (decoder_long_multiply == long_result);
      assert (decoder_accumulate == alu_accumulate);
      assert (decoder_signed_multiply ==
              ((multiply_kind == arm9_isa_pkg::ARM9_MULTIPLY_SMULL) ||
               (multiply_kind == arm9_isa_pkg::ARM9_MULTIPLY_SMLAL)));
    end
  end
`endif
endmodule
