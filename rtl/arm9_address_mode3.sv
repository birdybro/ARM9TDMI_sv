module arm9_address_mode3 (
  input  logic [31:0]                  instruction,
  input  logic [31:0]                  base_value,
  input  logic [31:0]                  index_value,
  output logic                         decode_match,
  output logic                         encoding_valid,
  output logic                         unpredictable_encoding,
  output logic                         unaligned_access_unpredictable,
  output logic [3:0]                   condition,
  output arm9_isa_pkg::arm9_misc_transfer_kind_e transfer_kind,
  output logic                         immediate_offset,
  output logic                         pre_index,
  output logic                         add_offset,
  output logic                         writeback,
  output logic                         load,
  output logic                         signed_transfer,
  output logic                         halfword_transfer,
  output logic [3:0]                   base_register,
  output logic [3:0]                   data_register,
  output logic [3:0]                   index_register,
  output logic [31:0]                  offset_value,
  output logic [31:0]                  effective_address,
  output logic [31:0]                  writeback_address
);
  import arm9_isa_pkg::*;

  logic s_bit;
  logic h_bit;
  logic common_operation;
  logic register_reserved_bits_nonzero;
  logic post_index_w_bit;
  logic base_uses_r15_with_writeback;
  logic data_base_writeback_collision;
  logic base_index_writeback_collision;
  logic index_uses_r15;
  logic data_uses_r15;

  always_comb begin
    condition        = instruction[31:28];
    pre_index        = instruction[24];
    add_offset       = instruction[23];
    immediate_offset = instruction[22];
    load             = instruction[20];
    base_register    = instruction[19:16];
    data_register    = instruction[15:12];
    index_register   = instruction[3:0];
    s_bit            = instruction[6];
    h_bit            = instruction[5];
    writeback        = !pre_index || instruction[21];
    signed_transfer  = s_bit;
    halfword_transfer = h_bit;

    case ({load, s_bit, h_bit})
      3'b001: transfer_kind = ARM9_MISC_TRANSFER_STRH;
      3'b101: transfer_kind = ARM9_MISC_TRANSFER_LDRH;
      3'b110: transfer_kind = ARM9_MISC_TRANSFER_LDRSB;
      3'b111: transfer_kind = ARM9_MISC_TRANSFER_LDRSH;
      default: transfer_kind = ARM9_MISC_TRANSFER_STRH;
    endcase

    common_operation = (!s_bit && h_bit) || (load && s_bit);
    decode_match = (condition != 4'b1111) &&
                   (instruction[27:25] == 3'b000) &&
                   instruction[7] && instruction[4] &&
                   common_operation;

    register_reserved_bits_nonzero = !immediate_offset &&
                                      (instruction[11:8] != 4'b0000);
    post_index_w_bit = !pre_index && instruction[21];
    base_uses_r15_with_writeback = writeback &&
                                   (base_register == 4'hf);
    data_base_writeback_collision = writeback &&
                                    (data_register == base_register);
    base_index_writeback_collision = !immediate_offset && writeback &&
                                     (base_register == index_register);
    index_uses_r15 = !immediate_offset && (index_register == 4'hf);
    data_uses_r15 = data_register == 4'hf;

    unpredictable_encoding = decode_match &&
      (register_reserved_bits_nonzero || post_index_w_bit ||
       base_uses_r15_with_writeback || data_base_writeback_collision ||
       base_index_writeback_collision || index_uses_r15 || data_uses_r15);
    encoding_valid = decode_match && !unpredictable_encoding;

    offset_value = immediate_offset ?
      {24'b0, instruction[11:8], instruction[3:0]} : index_value;
    if (add_offset) begin
      writeback_address = base_value + offset_value;
    end else begin
      writeback_address = base_value - offset_value;
    end
    effective_address = pre_index ? writeback_address : base_value;
    unaligned_access_unpredictable = encoding_valid &&
                                     halfword_transfer &&
                                     effective_address[0];
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(encoding_valid && !decode_match));
    assert (!(encoding_valid && unpredictable_encoding));
    assert (!(unaligned_access_unpredictable &&
              (!encoding_valid || !halfword_transfer ||
               !effective_address[0])));
    if (encoding_valid && !immediate_offset) begin
      assert (instruction[11:8] == 4'b0000);
      assert (index_register != 4'hf);
    end
    if (encoding_valid && writeback) begin
      assert (base_register != 4'hf);
      assert (data_register != base_register);
      if (!immediate_offset) begin
        assert (base_register != index_register);
      end
    end
    if (pre_index) begin
      assert (effective_address == writeback_address);
    end else begin
      assert (effective_address == base_value);
    end
  end
`endif
endmodule
