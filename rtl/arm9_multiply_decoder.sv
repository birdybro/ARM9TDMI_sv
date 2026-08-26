module arm9_multiply_decoder (
  input  logic [31:0]                         instruction,
  output logic                                decode_match,
  output logic                                encoding_valid,
  output logic                                unpredictable_encoding,
  output logic [3:0]                          condition,
  output arm9_isa_pkg::arm9_multiply_kind_e  multiply_kind,
  output logic                                set_flags,
  output logic                                long_multiply,
  output logic                                accumulate,
  output logic                                signed_multiply,
  output logic [3:0]                          destination_high_register,
  output logic [3:0]                          destination_low_register,
  output logic [3:0]                          multiplier_register,
  output logic [3:0]                          multiplicand_register
);
  import arm9_isa_pkg::*;

  logic short_multiply_match;
  logic long_multiply_match;
  logic sbz_violation;
  logic uses_accumulator;
  logic uses_two_destinations;
  logic uses_r15;

  always_comb begin
    condition                     = instruction[31:28];
    set_flags                     = instruction[20];
    accumulate                    = instruction[21];
    signed_multiply               = instruction[22];
    destination_high_register     = instruction[19:16];
    destination_low_register      = instruction[15:12];
    multiplier_register           = instruction[11:8];
    multiplicand_register         = instruction[3:0];

    short_multiply_match = (instruction[27:22] == 6'b000000) &&
                           (instruction[7:4] == 4'b1001);
    long_multiply_match  = (instruction[27:23] == 5'b00001) &&
                           (instruction[7:4] == 4'b1001);

    // Encoding diagrams whose top field is "cond" exclude 0b1111 in
    // ARMv5. ARMv4 assigns that condition value UNPREDICTABLE globally,
    // so it is deliberately left for the profile-level decoder.
    decode_match  = (condition != 4'b1111) &&
                    (short_multiply_match || long_multiply_match);
    long_multiply = decode_match && long_multiply_match;

    if (long_multiply_match) begin
      if (instruction[22]) begin
        multiply_kind = instruction[21] ? ARM9_MULTIPLY_SMLAL :
                                          ARM9_MULTIPLY_SMULL;
      end else begin
        multiply_kind = instruction[21] ? ARM9_MULTIPLY_UMLAL :
                                          ARM9_MULTIPLY_UMULL;
      end
    end else begin
      multiply_kind = instruction[21] ? ARM9_MULTIPLY_MLA :
                                        ARM9_MULTIPLY_MUL;
    end

    uses_accumulator      = short_multiply_match && instruction[21];
    uses_two_destinations = long_multiply_match;
    sbz_violation         = short_multiply_match && !instruction[21] &&
                            (instruction[15:12] != 4'b0000);
    uses_r15              = (destination_high_register == 4'hf) ||
                            (multiplier_register == 4'hf) ||
                            (multiplicand_register == 4'hf) ||
                            ((uses_accumulator || uses_two_destinations) &&
                             (destination_low_register == 4'hf));

    unpredictable_encoding = decode_match &&
      (sbz_violation || uses_r15 ||
       (uses_two_destinations &&
        (destination_high_register == destination_low_register)));
    encoding_valid = decode_match && !unpredictable_encoding;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(encoding_valid && !decode_match));
    assert (!(encoding_valid && unpredictable_encoding));
    assert (!(long_multiply && !decode_match));
  end
`endif
endmodule
