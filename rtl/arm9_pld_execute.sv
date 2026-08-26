module arm9_pld_execute #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM946ES
) (
  input  logic [31:0]                   instruction,
  input  logic [31:0]                   base_value,
  input  logic [31:0]                   index_value,
  input  logic                          carry_in,
  output logic                          decode_match,
  output logic                          profile_legal,
  output logic                          profile_illegal_encoding,
  output logic                          encoding_valid,
  output logic                          unpredictable_encoding,
  output logic                          unconditional_space,
  output logic                          execute_valid,
  output logic                          immediate_offset,
  output logic                          add_offset,
  output logic [3:0]                    base_register,
  output logic [3:0]                    index_register,
  output logic [4:0]                    shift_amount,
  output arm9_isa_pkg::arm9_shift_type_e shift_type,
  output logic [31:0]                   offset_value,
  output logic                          shift_carry_out,
  output logic [31:0]                   prefetch_address,
  output logic                          prefetch_address_valid,
  output logic                          data_speculative,
  output logic                          architectural_state_write_enable,
  output logic                          precise_data_abort_possible
);
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic register_offset;
  logic register_encoding_valid;
  logic [31:0] shifted_index;

  arm9_barrel_shifter index_shifter (
    .value(index_value),
    .shift_type,
    .shift_amount({3'b000, shift_amount}),
    .amount_from_register(1'b0),
    .carry_in,
    .result(shifted_index),
    .carry_out(shift_carry_out)
  );

  always_comb begin
    unconditional_space = instruction[31:28] == 4'hf;
    register_offset = instruction[25];
    immediate_offset = !register_offset;
    add_offset = instruction[23];
    base_register = instruction[19:16];
    index_register = instruction[3:0];
    shift_amount = instruction[11:7];
    shift_type = arm9_shift_type_e'(instruction[6:5]);
    register_encoding_valid = !register_offset || !instruction[4];

    // P and W are deliberately omitted from decode_match. DDI0100I defines
    // P=0 or W=1 PLD forms as UNPREDICTABLE rather than unrelated opcodes.
    decode_match = unconditional_space &&
                   (instruction[27:26] == 2'b01) &&
                   instruction[22] && instruction[20] &&
                   (instruction[15:12] == 4'hf) &&
                   register_encoding_valid;
    profile_legal = decode_match && (PROFILE == ARM9_PROFILE_ARM946ES);
    profile_illegal_encoding = decode_match && !profile_legal;
    unpredictable_encoding = profile_legal &&
      (!instruction[24] || instruction[21] ||
       (register_offset && (index_register == 4'hf)));
    encoding_valid = profile_legal && !unpredictable_encoding;
    execute_valid = encoding_valid;

    offset_value = immediate_offset ? {20'b0, instruction[11:0]} :
                                      shifted_index;
    prefetch_address = add_offset ? (base_value + offset_value) :
                                    (base_value - offset_value);
    prefetch_address_valid = execute_valid;
    data_speculative = execute_valid;
    architectural_state_write_enable = 1'b0;
    precise_data_abort_possible = 1'b0;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(encoding_valid && !profile_legal));
    assert (!(unpredictable_encoding && !profile_legal));
    assert (!(execute_valid && !encoding_valid));
    assert (prefetch_address_valid == execute_valid);
    assert (data_speculative == execute_valid);
    assert (!architectural_state_write_enable);
    assert (!precise_data_abort_possible);
    if (encoding_valid) begin
      assert (unconditional_space);
      assert (instruction[24] && !instruction[21]);
      assert (!register_offset || (index_register != 4'hf));
    end
  end
`endif
endmodule
