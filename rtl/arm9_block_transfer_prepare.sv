module arm9_block_transfer_prepare (
  input  logic [31:0]                instruction,
  input  logic [31:0]                base_value,
  input  arm9_arch_pkg::arm9_mode_e  current_mode,
  input  logic                       negative,
  input  logic                       zero,
  input  logic                       carry,
  input  logic                       overflow,
  output logic                       decode_match,
  output logic                       encoding_valid,
  output logic                       unpredictable_encoding,
  output logic                       condition_passed,
  output logic                       unconditional_space,
  output logic                       unpredictable_operation,
  output logic                       execute_valid,
  output logic                       transfer_load,
  output logic                       transfer_store,
  output logic [3:0]                 base_register,
  output logic [15:0]                register_list,
  output logic [4:0]                 register_count,
  output logic [3:0]                 first_register,
  output logic [3:0]                 last_register,
  output logic                       memory_sequence_valid,
  output logic [4:0]                 memory_word_count,
  output logic [31:0]                first_word_address,
  output logic [31:0]                last_word_address,
  output logic                       addresses_ascending,
  output logic                       unaligned_base,
  output logic                       transfer_user_bank,
  output logic                       pc_load_pending,
  output logic                       restore_cpsr_pending,
  output logic                       base_writeback_pending,
  output logic [31:0]                base_writeback_value,
  output logic                       base_writeback_value_unpredictable,
  output logic                       store_base_uses_original_value,
  output logic                       store_base_value_unpredictable
);
  logic       decoded_pre_index;
  logic       decoded_increment;
  logic       decoded_psr_or_user;
  logic       decoded_writeback;
  logic       decoded_load_pc;
  logic       decoded_user_bank_transfer;
  logic       decoded_restore_cpsr;
  logic       decoded_privileged_mode_required;
  logic       decoded_spsr_required;
  logic       decoded_base_in_register_list;
  logic       decoded_load_base_writeback_unpredictable;
  logic       decoded_store_base_uses_original_value;
  logic       decoded_store_base_value_unpredictable;
  logic [3:0] decoded_condition;
  logic       condition_result;
  logic       condition_unconditional;
  logic       current_mode_has_spsr;

  arm9_address_mode4 addressing (
    .instruction,
    .base_value,
    .decode_match,
    .encoding_valid,
    .unpredictable_encoding,
    .condition(decoded_condition),
    .pre_index(decoded_pre_index),
    .increment(decoded_increment),
    .psr_or_user(decoded_psr_or_user),
    .writeback(decoded_writeback),
    .load(transfer_load),
    .base_register,
    .register_list,
    .register_count,
    .first_register,
    .last_register,
    .load_pc(decoded_load_pc),
    .user_bank_transfer(decoded_user_bank_transfer),
    .restore_cpsr(decoded_restore_cpsr),
    .privileged_mode_required(decoded_privileged_mode_required),
    .spsr_required(decoded_spsr_required),
    .base_in_register_list(decoded_base_in_register_list),
    .load_base_writeback_unpredictable(
      decoded_load_base_writeback_unpredictable
    ),
    .store_base_uses_original_value(
      decoded_store_base_uses_original_value
    ),
    .store_base_value_unpredictable(
      decoded_store_base_value_unpredictable
    ),
    .unaligned_base,
    .start_address(first_word_address),
    .end_address(last_word_address),
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
    current_mode_has_spsr = arm9_arch_pkg::mode_has_spsr(current_mode);
    condition_passed = condition_result;
    unconditional_space = condition_unconditional;
    unpredictable_operation = encoding_valid && condition_result &&
                              decoded_privileged_mode_required &&
                              !current_mode_has_spsr;
    execute_valid = encoding_valid && condition_result &&
                    !unpredictable_operation;

    transfer_store = !transfer_load;
    memory_sequence_valid = execute_valid;
    memory_word_count = execute_valid ? register_count : 5'b0;
    addresses_ascending = execute_valid;
    transfer_user_bank = execute_valid && decoded_user_bank_transfer;
    pc_load_pending = execute_valid && decoded_load_pc;
    restore_cpsr_pending = execute_valid && decoded_restore_cpsr;
    base_writeback_pending = execute_valid && decoded_writeback;
    base_writeback_value_unpredictable = execute_valid &&
      decoded_load_base_writeback_unpredictable;
    store_base_uses_original_value = execute_valid &&
      decoded_store_base_uses_original_value;
    store_base_value_unpredictable = execute_valid &&
      decoded_store_base_value_unpredictable;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(unpredictable_operation &&
              (!encoding_valid || !condition_passed ||
               !decoded_privileged_mode_required ||
               current_mode_has_spsr)));
    assert (!(execute_valid &&
              (!encoding_valid || !condition_passed ||
               unpredictable_operation)));
    assert (memory_sequence_valid == execute_valid);
    assert (memory_word_count ==
            (execute_valid ? register_count : 5'b0));
    assert (!(transfer_user_bank &&
              (!execute_valid || !decoded_user_bank_transfer)));
    assert (!(pc_load_pending && (!execute_valid || !transfer_load)));
    assert (!(restore_cpsr_pending &&
              (!pc_load_pending || !decoded_spsr_required ||
               !current_mode_has_spsr)));
    assert (!(base_writeback_pending &&
              (!execute_valid || !decoded_writeback)));
    assert (!(base_writeback_value_unpredictable &&
              (!base_writeback_pending || !transfer_load ||
               !decoded_base_in_register_list)));
    assert (!(store_base_uses_original_value &&
              store_base_value_unpredictable));
    assert (!$isunknown(decoded_pre_index));
    assert (!$isunknown(decoded_increment));
    assert (!$isunknown(decoded_psr_or_user));
    if (decode_match) begin
      assert (decoded_condition == instruction[31:28]);
    end
    if (execute_valid) begin
      assert (register_count != 5'b0);
      assert (first_word_address[1:0] == 2'b00);
      assert (last_word_address[1:0] == 2'b00);
      assert (last_word_address == first_word_address +
              ({25'b0, register_count, 2'b00} - 32'd4));
    end
  end
`endif
endmodule
