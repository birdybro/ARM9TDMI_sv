module arm9_single_transfer_prepare (
  input  logic [31:0] instruction,
  input  logic [31:0] base_value,
  input  logic [31:0] index_value,
  input  logic [31:0] store_register_value,
  input  logic        negative,
  input  logic        zero,
  input  logic        carry,
  input  logic        overflow,
  output logic        decode_match,
  output logic        encoding_valid,
  output logic        unpredictable_encoding,
  output logic        unpredictable_access,
  output logic        condition_passed,
  output logic        unconditional_space,
  output logic        execute_valid,
  output logic        transfer_load,
  output logic        transfer_byte,
  output logic        translated_access,
  output logic [3:0]  base_register,
  output logic [3:0]  data_register,
  output logic [3:0]  index_register,
  output logic        memory_request_valid,
  output logic        memory_write,
  output logic        memory_byte_transfer,
  output logic        memory_unprivileged,
  output logic [31:0] memory_address,
  output logic [31:0] memory_write_value,
  output logic [7:0]  memory_write_byte_value,
  output logic        base_writeback_pending,
  output logic [31:0] base_writeback_value,
  output logic        store_pc_value_implementation_defined
);
  logic [3:0] decoded_condition;
  logic decoded_writeback;
  logic decoded_immediate_offset;
  logic decoded_pre_index;
  logic decoded_add_offset;
  logic [4:0] decoded_shift_amount;
  arm9_isa_pkg::arm9_shift_type_e decoded_shift_type;
  logic [31:0] decoded_offset_value;
  logic decoded_shift_carry;
  logic condition_result;
  logic condition_unconditional;

  arm9_address_mode2 addressing (
    .instruction,
    .base_value,
    .index_value,
    .carry_in(carry),
    .decode_match,
    .encoding_valid,
    .unpredictable_encoding,
    .condition(decoded_condition),
    .immediate_offset(decoded_immediate_offset),
    .pre_index(decoded_pre_index),
    .add_offset(decoded_add_offset),
    .byte_transfer(transfer_byte),
    .writeback(decoded_writeback),
    .load(transfer_load),
    .unprivileged_access(translated_access),
    .base_register,
    .data_register,
    .index_register,
    .shift_amount(decoded_shift_amount),
    .shift_type(decoded_shift_type),
    .offset_value(decoded_offset_value),
    .shift_carry_out(decoded_shift_carry),
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
    condition_passed    = condition_result;
    unconditional_space = condition_unconditional;
    unpredictable_access = encoding_valid && condition_result &&
      transfer_load && !transfer_byte && (data_register == 4'hf) &&
      (memory_address[1:0] != 2'b00);
    execute_valid = encoding_valid && condition_result &&
                    !unpredictable_access;
    memory_request_valid = execute_valid;
    memory_write         = execute_valid && !transfer_load;
    memory_byte_transfer = execute_valid && transfer_byte;
    memory_unprivileged  = execute_valid && translated_access;
    memory_write_value      = store_register_value;
    memory_write_byte_value = store_register_value[7:0];
    base_writeback_pending = execute_valid && decoded_writeback;
    store_pc_value_implementation_defined = encoding_valid &&
      !transfer_load && !transfer_byte && (data_register == 4'hf);
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(execute_valid &&
              (!encoding_valid || !condition_passed ||
               unpredictable_access)));
    assert (!(unpredictable_access &&
              (!encoding_valid || !condition_passed || !transfer_load ||
               transfer_byte || (data_register != 4'hf))));
    assert (memory_request_valid == execute_valid);
    assert (!(memory_write && (!memory_request_valid || transfer_load)));
    assert (!(memory_byte_transfer && !memory_request_valid));
    assert (!(memory_unprivileged &&
              (!memory_request_valid || !translated_access)));
    assert (!(base_writeback_pending &&
              (!memory_request_valid || !decoded_writeback)));
    if (decode_match) begin
      assert (decoded_condition == instruction[31:28]);
      assert (decoded_immediate_offset == !instruction[25]);
      assert (decoded_pre_index == instruction[24]);
      assert (decoded_add_offset == instruction[23]);
      assert (decoded_shift_amount == instruction[11:7]);
      assert (decoded_shift_type ==
              arm9_isa_pkg::arm9_shift_type_e'(instruction[6:5]));
      assert (!$isunknown(decoded_shift_carry));
      if (decoded_add_offset) begin
        assert (base_writeback_value == base_value + decoded_offset_value);
      end else begin
        assert (base_writeback_value == base_value - decoded_offset_value);
      end
    end
  end
`endif
endmodule
