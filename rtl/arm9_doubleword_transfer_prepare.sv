module arm9_doubleword_transfer_prepare #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic [31:0] instruction,
  input  logic [31:0] base_value,
  input  logic [31:0] index_value,
  input  logic [31:0] first_store_register_value,
  input  logic [31:0] second_store_register_value,
  input  logic        negative,
  input  logic        zero,
  input  logic        carry,
  input  logic        overflow,
  output logic        decode_match,
  output logic        profile_legal,
  output logic        profile_illegal_encoding,
  output logic        undefined_encoding,
  output logic        unpredictable_encoding,
  output logic        unpredictable_access,
  output logic        encoding_valid,
  output logic        condition_passed,
  output logic        unconditional_space,
  output logic        execute_valid,
  output logic        transfer_load,
  output logic [3:0]  base_register,
  output logic [3:0]  first_data_register,
  output logic [3:0]  second_data_register,
  output logic [3:0]  index_register,
  output logic        memory_sequence_valid,
  output logic        memory_write,
  output logic [31:0] first_word_address,
  output logic [31:0] second_word_address,
  output logic [31:0] first_store_value,
  output logic [31:0] second_store_value,
  output logic        base_writeback_pending,
  output logic [31:0] base_writeback_value
);
  logic       decoded_unaligned_access;
  logic       decoded_immediate_offset;
  logic       decoded_pre_index;
  logic       decoded_add_offset;
  logic       decoded_writeback;
  logic [3:0] decoded_condition;
  logic [31:0] decoded_offset_value;
  logic       condition_result;
  logic       condition_unconditional;

  arm9_doubleword_transfer_decode #(
    .PROFILE(PROFILE)
  ) decoder (
    .instruction,
    .base_value,
    .index_value,
    .decode_match,
    .profile_legal,
    .profile_illegal_encoding,
    .undefined_encoding,
    .unpredictable_encoding,
    .encoding_valid,
    .unaligned_access_unpredictable(decoded_unaligned_access),
    .condition(decoded_condition),
    .transfer_load,
    .immediate_offset(decoded_immediate_offset),
    .pre_index(decoded_pre_index),
    .add_offset(decoded_add_offset),
    .writeback(decoded_writeback),
    .base_register,
    .first_data_register,
    .second_data_register,
    .index_register,
    .offset_value(decoded_offset_value),
    .effective_address(first_word_address),
    .second_word_address,
    .writeback_address(base_writeback_value)
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
    unpredictable_access = encoding_valid && condition_result &&
                           decoded_unaligned_access;
    execute_valid = encoding_valid && condition_result &&
                    !decoded_unaligned_access;
    memory_sequence_valid = execute_valid;
    memory_write = execute_valid && !transfer_load;
    first_store_value = first_store_register_value;
    second_store_value = second_store_register_value;
    base_writeback_pending = execute_valid && decoded_writeback;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(execute_valid &&
              (!encoding_valid || !condition_passed ||
               decoded_unaligned_access)));
    assert (!(unpredictable_access &&
              (!encoding_valid || !condition_passed ||
               !decoded_unaligned_access)));
    assert (memory_sequence_valid == execute_valid);
    assert (!(memory_write &&
              (!memory_sequence_valid || transfer_load)));
    assert (!(base_writeback_pending &&
              (!memory_sequence_valid || !decoded_writeback)));
    assert (second_word_address == first_word_address + 32'd4);
    if (decode_match) begin
      assert (decoded_condition == instruction[31:28]);
      assert (!$isunknown(decoded_immediate_offset));
      assert (!$isunknown(decoded_pre_index));
      assert (!$isunknown(decoded_add_offset));
      assert (!$isunknown(decoded_offset_value));
    end
  end
`endif
endmodule
