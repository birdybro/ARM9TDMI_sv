module arm9_doubleword_transfer_decode #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic [31:0] instruction,
  input  logic [31:0] base_value,
  input  logic [31:0] index_value,
  output logic        decode_match,
  output logic        profile_legal,
  output logic        profile_illegal_encoding,
  output logic        undefined_encoding,
  output logic        unpredictable_encoding,
  output logic        encoding_valid,
  output logic        unaligned_access_unpredictable,
  output logic [3:0]  condition,
  output logic        transfer_load,
  output logic        immediate_offset,
  output logic        pre_index,
  output logic        add_offset,
  output logic        writeback,
  output logic [3:0]  base_register,
  output logic [3:0]  first_data_register,
  output logic [3:0]  second_data_register,
  output logic [3:0]  index_register,
  output logic [31:0] offset_value,
  output logic [31:0] effective_address,
  output logic [31:0] second_word_address,
  output logic [31:0] writeback_address
);
  import arm9_profile_pkg::*;

  logic register_reserved_bits_nonzero;
  logic post_index_w_bit;
  logic base_uses_r15_with_writeback;
  logic base_data_writeback_collision;
  logic base_index_writeback_collision;
  logic index_uses_r15;
  logic load_index_data_collision;
  logic data_uses_r14;

  always_comb begin
    condition           = instruction[31:28];
    pre_index           = instruction[24];
    add_offset          = instruction[23];
    immediate_offset    = instruction[22];
    writeback           = !pre_index || instruction[21];
    transfer_load       = !instruction[5];
    base_register       = instruction[19:16];
    first_data_register = instruction[15:12];
    second_data_register = instruction[15:12] + 4'd1;
    index_register      = instruction[3:0];

    decode_match = (condition != 4'b1111) &&
                   (instruction[27:25] == 3'b000) &&
                   !instruction[20] && instruction[7] && instruction[6] &&
                   instruction[4];
    profile_legal = decode_match && (PROFILE == ARM9_PROFILE_ARM946ES);
    profile_illegal_encoding = decode_match && !profile_legal;

    undefined_encoding = profile_legal && first_data_register[0];
    register_reserved_bits_nonzero = !immediate_offset &&
                                      (instruction[11:8] != 4'b0000);
    post_index_w_bit = !pre_index && instruction[21];
    base_uses_r15_with_writeback = writeback &&
                                   (base_register == 4'hf);
    base_data_writeback_collision = writeback &&
      ((base_register == first_data_register) ||
       (base_register == second_data_register));
    base_index_writeback_collision = !immediate_offset && writeback &&
                                     (base_register == index_register);
    index_uses_r15 = !immediate_offset && (index_register == 4'hf);
    load_index_data_collision = transfer_load && !immediate_offset &&
      ((index_register == first_data_register) ||
       (index_register == second_data_register));
    data_uses_r14 = first_data_register == 4'he;

    unpredictable_encoding = profile_legal && !undefined_encoding &&
      (register_reserved_bits_nonzero || post_index_w_bit ||
       base_uses_r15_with_writeback || base_data_writeback_collision ||
       base_index_writeback_collision || index_uses_r15 ||
       load_index_data_collision || data_uses_r14);
    encoding_valid = profile_legal && !undefined_encoding &&
                     !unpredictable_encoding;

    offset_value = immediate_offset ?
      {24'b0, instruction[11:8], instruction[3:0]} : index_value;
    if (add_offset) begin
      writeback_address = base_value + offset_value;
    end else begin
      writeback_address = base_value - offset_value;
    end
    effective_address = pre_index ? writeback_address : base_value;
    second_word_address = effective_address + 32'd4;
    unaligned_access_unpredictable = encoding_valid &&
                                     (effective_address[2:0] != 3'b000);
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(profile_legal && !decode_match));
    assert (!(profile_illegal_encoding && profile_legal));
    assert (!(undefined_encoding && (!profile_legal ||
                                      !first_data_register[0])));
    assert (!(unpredictable_encoding &&
              (!profile_legal || undefined_encoding)));
    assert (!(encoding_valid &&
              (!profile_legal || undefined_encoding ||
               unpredictable_encoding)));
    assert (!(unaligned_access_unpredictable &&
              (!encoding_valid || (effective_address[2:0] == 3'b000))));
    if (encoding_valid) begin
      assert (!first_data_register[0]);
      assert (first_data_register != 4'he);
      assert (second_data_register == first_data_register + 4'd1);
    end
    if (pre_index) begin
      assert (effective_address == writeback_address);
    end else begin
      assert (effective_address == base_value);
    end
    assert (second_word_address == effective_address + 32'd4);
  end
`endif
endmodule
