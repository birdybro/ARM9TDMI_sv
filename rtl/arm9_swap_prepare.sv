module arm9_swap_prepare (
  input  logic [31:0] instruction,
  input  logic [31:0] base_value,
  input  logic [31:0] source_register_value,
  input  logic        negative,
  input  logic        zero,
  input  logic        carry,
  input  logic        overflow,
  output logic        decode_match,
  output logic        encoding_valid,
  output logic        unpredictable_encoding,
  output logic        condition_passed,
  output logic        unconditional_space,
  output logic        execute_valid,
  output logic        byte_swap,
  output logic [3:0]  base_register,
  output logic [3:0]  destination_register,
  output logic [3:0]  source_register,
  output logic        atomic_sequence_valid,
  output logic        atomic_lock_required,
  output logic        read_then_write_required,
  output logic        memory_byte_transfer,
  output logic [31:0] read_access_address,
  output logic [31:0] write_access_address,
  output logic [1:0]  original_address_low,
  output logic        loaded_word_rotation_required,
  output logic [31:0] store_value,
  output logic [7:0]  store_byte_value
);
  logic condition_result;
  logic condition_unconditional;
  logic [3:0] decoded_condition;

  arm9_swap_decoder decoder (
    .instruction,
    .decode_match,
    .encoding_valid,
    .unpredictable_encoding,
    .condition(decoded_condition),
    .byte_swap,
    .base_register,
    .destination_register,
    .source_register
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
    execute_valid = encoding_valid && condition_result;
    atomic_sequence_valid = execute_valid;
    atomic_lock_required = execute_valid;
    read_then_write_required = execute_valid;
    memory_byte_transfer = execute_valid && byte_swap;
    original_address_low = base_value[1:0];
    if (byte_swap) begin
      read_access_address = base_value;
      write_access_address = base_value;
    end else begin
      read_access_address = {base_value[31:2], 2'b00};
      write_access_address = {base_value[31:2], 2'b00};
    end
    loaded_word_rotation_required = execute_valid && !byte_swap &&
                                    (base_value[1:0] != 2'b00);
    store_value = source_register_value;
    store_byte_value = source_register_value[7:0];
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(execute_valid && (!encoding_valid || !condition_passed)));
    assert (atomic_sequence_valid == execute_valid);
    assert (atomic_lock_required == atomic_sequence_valid);
    assert (read_then_write_required == atomic_sequence_valid);
    assert (read_access_address == write_access_address);
    assert (!(loaded_word_rotation_required &&
              (!execute_valid || byte_swap ||
               (original_address_low == 2'b00))));
    assert (store_byte_value == store_value[7:0]);
    if (decode_match) begin
      assert (decoded_condition == instruction[31:28]);
    end
    if (!byte_swap) begin
      assert (read_access_address[1:0] == 2'b00);
    end
  end
`endif
endmodule
