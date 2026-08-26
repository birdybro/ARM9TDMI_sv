module arm9_swap_decoder (
  input  logic [31:0] instruction,
  output logic        decode_match,
  output logic        encoding_valid,
  output logic        unpredictable_encoding,
  output logic [3:0]  condition,
  output logic        byte_swap,
  output logic [3:0]  base_register,
  output logic [3:0]  destination_register,
  output logic [3:0]  source_register
);
  logic reserved_bits_nonzero;
  logic register_uses_r15;
  logic base_register_collision;

  always_comb begin
    condition = instruction[31:28];
    byte_swap = instruction[22];
    base_register = instruction[19:16];
    destination_register = instruction[15:12];
    source_register = instruction[3:0];

    decode_match = (condition != 4'b1111) &&
                   (instruction[27:23] == 5'b00010) &&
                   (instruction[21:20] == 2'b00) &&
                   (instruction[7:4] == 4'b1001);
    reserved_bits_nonzero = instruction[11:8] != 4'b0000;
    register_uses_r15 = (base_register == 4'hf) ||
                        (destination_register == 4'hf) ||
                        (source_register == 4'hf);
    base_register_collision = (base_register == destination_register) ||
                              (base_register == source_register);
    unpredictable_encoding = decode_match &&
      (reserved_bits_nonzero || register_uses_r15 ||
       base_register_collision);
    encoding_valid = decode_match && !unpredictable_encoding;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(encoding_valid && !decode_match));
    assert (!(encoding_valid && unpredictable_encoding));
    if (encoding_valid) begin
      assert (instruction[11:8] == 4'b0000);
      assert (base_register != 4'hf);
      assert (destination_register != 4'hf);
      assert (source_register != 4'hf);
      assert (base_register != destination_register);
      assert (base_register != source_register);
    end
  end
`endif
endmodule
