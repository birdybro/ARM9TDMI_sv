module arm9_address_mode2 (
  input  logic [31:0]                  instruction,
  input  logic [31:0]                  base_value,
  input  logic [31:0]                  index_value,
  input  logic                         carry_in,
  output logic                         decode_match,
  output logic                         encoding_valid,
  output logic                         unpredictable_encoding,
  output logic [3:0]                   condition,
  output logic                         immediate_offset,
  output logic                         pre_index,
  output logic                         add_offset,
  output logic                         byte_transfer,
  output logic                         writeback,
  output logic                         load,
  output logic                         unprivileged_access,
  output logic [3:0]                   base_register,
  output logic [3:0]                   data_register,
  output logic [3:0]                   index_register,
  output logic [4:0]                   shift_amount,
  output arm9_isa_pkg::arm9_shift_type_e shift_type,
  output logic [31:0]                  offset_value,
  output logic                         shift_carry_out,
  output logic [31:0]                  effective_address,
  output logic [31:0]                  writeback_address
);
  import arm9_isa_pkg::*;

  logic register_offset;
  logic register_encoding_valid;
  logic [31:0] shifted_index;
  logic base_uses_r15_with_writeback;
  logic data_base_writeback_collision;
  logic base_index_writeback_collision;
  logic index_uses_r15;
  logic byte_uses_r15;

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
    condition        = instruction[31:28];
    register_offset  = instruction[25];
    immediate_offset = !register_offset;
    pre_index        = instruction[24];
    add_offset       = instruction[23];
    byte_transfer    = instruction[22];
    load             = instruction[20];
    base_register    = instruction[19:16];
    data_register    = instruction[15:12];
    shift_amount     = instruction[11:7];
    shift_type       = arm9_shift_type_e'(instruction[6:5]);
    index_register   = instruction[3:0];
    writeback        = !pre_index || instruction[21];
    unprivileged_access = !pre_index && instruction[21];

    register_encoding_valid = !register_offset || !instruction[4];
    decode_match = (condition != 4'b1111) &&
                   (instruction[27:26] == 2'b01) &&
                   register_encoding_valid;

    base_uses_r15_with_writeback = writeback &&
      (base_register == 4'hf);
    data_base_writeback_collision = writeback &&
      (data_register == base_register);
    base_index_writeback_collision = register_offset && writeback &&
      (base_register == index_register);
    index_uses_r15 = register_offset && (index_register == 4'hf);
    byte_uses_r15 = byte_transfer && (data_register == 4'hf);
    unpredictable_encoding = decode_match &&
      (base_uses_r15_with_writeback ||
       data_base_writeback_collision ||
       base_index_writeback_collision || index_uses_r15 || byte_uses_r15);
    encoding_valid = decode_match && !unpredictable_encoding;

    offset_value = immediate_offset ? {20'b0, instruction[11:0]} :
                                      shifted_index;
    if (add_offset) begin
      writeback_address = base_value + offset_value;
    end else begin
      writeback_address = base_value - offset_value;
    end
    effective_address = pre_index ? writeback_address : base_value;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(encoding_valid && !decode_match));
    assert (!(encoding_valid && unpredictable_encoding));
    assert (!(unprivileged_access && (!writeback || pre_index)));
    if (decode_match && register_offset) begin
      assert (!instruction[4]);
    end
    if (encoding_valid && writeback) begin
      assert (base_register != 4'hf);
      assert (data_register != base_register);
    end
    if (pre_index) begin
      assert (effective_address == writeback_address);
    end else begin
      assert (effective_address == base_value);
    end
  end
`endif
endmodule
