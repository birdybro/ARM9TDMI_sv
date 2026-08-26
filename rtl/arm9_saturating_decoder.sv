module arm9_saturating_decoder #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic [31:0]                            instruction,
  output logic                                   decode_match,
  output logic                                   profile_legal,
  output logic                                   profile_illegal_encoding,
  output logic                                   encoding_valid,
  output logic                                   unpredictable_encoding,
  output logic [3:0]                             condition,
  output arm9_isa_pkg::arm9_saturating_kind_e   saturating_kind,
  output logic [3:0]                             destination_register,
  output logic [3:0]                             first_operand_register,
  output logic [3:0]                             second_operand_register
);
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic operation_match;
  logic fixed_fields_match;
  logic uses_r15;

  always_comb begin
    condition               = instruction[31:28];
    second_operand_register = instruction[19:16];
    destination_register    = instruction[15:12];
    first_operand_register  = instruction[3:0];
    saturating_kind = arm9_saturating_kind_e'(instruction[22:21]);

    operation_match = (instruction[27:23] == 5'b00010) &&
                      !instruction[20];
    fixed_fields_match = instruction[11:4] == 8'h05;
    decode_match = (condition != 4'b1111) && operation_match &&
                   fixed_fields_match;
    profile_legal = decode_match && (PROFILE == ARM9_PROFILE_ARM946ES);
    profile_illegal_encoding = decode_match && !profile_legal;
    uses_r15 = (destination_register == 4'hf) ||
               (first_operand_register == 4'hf) ||
               (second_operand_register == 4'hf);
    unpredictable_encoding = profile_legal && uses_r15;
    encoding_valid = profile_legal && !unpredictable_encoding;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(profile_legal && profile_illegal_encoding));
    assert (!(encoding_valid && !profile_legal));
    assert (!(unpredictable_encoding && !profile_legal));
    if (decode_match) begin
      assert (instruction[11:8] == 4'b0000);
      assert (instruction[7:4] == 4'b0101);
    end
  end
`endif
endmodule
