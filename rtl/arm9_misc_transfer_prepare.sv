module arm9_misc_transfer_prepare (
  input  logic [31:0]                  instruction,
  input  logic [31:0]                  base_value,
  input  logic [31:0]                  index_value,
  input  logic [31:0]                  store_register_value,
  input  logic                         negative,
  input  logic                         zero,
  input  logic                         carry,
  input  logic                         overflow,
  output logic                         decode_match,
  output logic                         encoding_valid,
  output logic                         unpredictable_encoding,
  output logic                         unpredictable_access,
  output logic                         condition_passed,
  output logic                         unconditional_space,
  output logic                         execute_valid,
  output arm9_isa_pkg::arm9_misc_transfer_kind_e transfer_kind,
  output logic                         transfer_load,
  output logic                         transfer_signed,
  output logic                         transfer_halfword,
  output logic [3:0]                   base_register,
  output logic [3:0]                   data_register,
  output logic [3:0]                   index_register,
  output logic                         memory_request_valid,
  output logic                         memory_write,
  output logic                         memory_byte_transfer,
  output logic                         memory_halfword_transfer,
  output logic [31:0]                  memory_address,
  output logic [31:0]                  memory_write_value,
  output logic [15:0]                  memory_write_halfword_value,
  output logic                         base_writeback_pending,
  output logic [31:0]                  base_writeback_value
);
  import arm9_isa_pkg::*;

  logic       decoded_immediate_offset;
  logic [3:0] decoded_condition;
  logic       decoded_pre_index;
  logic       decoded_add_offset;
  logic       decoded_writeback;
  logic [31:0] decoded_offset_value;
  logic       decoded_unaligned_access;
  logic       condition_result;
  logic       condition_unconditional;

  arm9_address_mode3 addressing (
    .instruction,
    .base_value,
    .index_value,
    .decode_match,
    .encoding_valid,
    .unpredictable_encoding,
    .unaligned_access_unpredictable(decoded_unaligned_access),
    .condition(decoded_condition),
    .transfer_kind,
    .immediate_offset(decoded_immediate_offset),
    .pre_index(decoded_pre_index),
    .add_offset(decoded_add_offset),
    .writeback(decoded_writeback),
    .load(transfer_load),
    .signed_transfer(transfer_signed),
    .halfword_transfer(transfer_halfword),
    .base_register,
    .data_register,
    .index_register,
    .offset_value(decoded_offset_value),
    .effective_address(memory_address),
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
    memory_request_valid = execute_valid;
    memory_write = execute_valid &&
                   (transfer_kind == ARM9_MISC_TRANSFER_STRH);
    memory_byte_transfer = execute_valid &&
                           (transfer_kind == ARM9_MISC_TRANSFER_LDRSB);
    memory_halfword_transfer = execute_valid && !memory_byte_transfer;
    memory_write_value = store_register_value;
    memory_write_halfword_value = store_register_value[15:0];
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
    assert (memory_request_valid == execute_valid);
    assert (!(memory_write &&
              (!memory_request_valid || transfer_load)));
    assert (!(memory_byte_transfer &&
              (!memory_request_valid || transfer_halfword)));
    assert (!(memory_halfword_transfer &&
              (!memory_request_valid || !transfer_halfword)));
    assert (!(memory_byte_transfer && memory_halfword_transfer));
    assert (!(base_writeback_pending &&
              (!memory_request_valid || !decoded_writeback)));
    assert (memory_write_halfword_value == memory_write_value[15:0]);

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
