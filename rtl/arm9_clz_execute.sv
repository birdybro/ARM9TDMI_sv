module arm9_clz_execute #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic [31:0] instruction,
  input  logic [31:0] source_value,
  input  logic        negative,
  input  logic        zero,
  input  logic        carry,
  input  logic        overflow,
  output logic        decode_match,
  output logic        profile_legal,
  output logic        profile_illegal_encoding,
  output logic        encoding_valid,
  output logic        unpredictable_encoding,
  output logic        condition_passed,
  output logic        unconditional_space,
  output logic        execute_valid,
  output logic [3:0]  destination_register,
  output logic [3:0]  source_register,
  output logic        destination_write_enable,
  output logic [31:0] destination_write_data,
  output logic        flags_write_enable
);
  import arm9_profile_pkg::*;

  logic condition_result;
  logic condition_unconditional;
  logic leading_one_found;
  logic [5:0] leading_zero_count;

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
    destination_register = instruction[15:12];
    source_register      = instruction[3:0];
    decode_match = (instruction[31:28] != 4'b1111) &&
                   ((instruction & 32'h0fff_0ff0) == 32'h016f_0f10);
    profile_legal = decode_match && (PROFILE == ARM9_PROFILE_ARM946ES);
    profile_illegal_encoding = decode_match && !profile_legal;
    unpredictable_encoding = profile_legal &&
      ((destination_register == 4'hf) || (source_register == 4'hf));
    encoding_valid = profile_legal && !unpredictable_encoding;
    condition_passed    = condition_result;
    unconditional_space = condition_unconditional;
    execute_valid = encoding_valid && condition_result;

    leading_zero_count = 6'd32;
    leading_one_found  = 1'b0;
    for (int unsigned bit_number = 0; bit_number < 32; bit_number++) begin
      if (!leading_one_found && source_value[31-bit_number]) begin
        leading_zero_count = bit_number[5:0];
        leading_one_found  = 1'b1;
      end
    end

    destination_write_enable = execute_valid;
    destination_write_data   = {26'b0, leading_zero_count};
    flags_write_enable       = 1'b0;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(encoding_valid && !profile_legal));
    assert (!(unpredictable_encoding && !profile_legal));
    assert (!(execute_valid && (!encoding_valid || !condition_passed)));
    assert (!(destination_write_enable && !execute_valid));
    assert (!flags_write_enable);
    assert (leading_zero_count <= 6'd32);
    assert (destination_write_data <= 32'd32);
  end
`endif
endmodule
