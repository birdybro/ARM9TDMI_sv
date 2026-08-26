module arm9_dsp_multiply_decoder #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic [31:0]                             instruction,
  output logic                                    decode_match,
  output logic                                    profile_legal,
  output logic                                    profile_illegal_encoding,
  output logic                                    encoding_valid,
  output logic                                    unpredictable_encoding,
  output logic [3:0]                              condition,
  output arm9_isa_pkg::arm9_dsp_multiply_kind_e  dsp_multiply_kind,
  output arm9_isa_pkg::arm9_multiply_kind_e      timing_kind,
  output logic                                    x_bit,
  output logic                                    y_bit,
  output logic [3:0]                              destination_high_register,
  output logic [3:0]                              accumulator_or_low_register,
  output logic [3:0]                              multiplier_register,
  output logic [3:0]                              multiplicand_register
);
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic extension_match;
  logic allocated_operation;
  logic uses_accumulator_or_low;
  logic uses_two_destinations;
  logic sbz_violation;
  logic uses_r15;

  always_comb begin
    condition                    = instruction[31:28];
    destination_high_register    = instruction[19:16];
    accumulator_or_low_register  = instruction[15:12];
    multiplier_register          = instruction[11:8];
    y_bit                        = instruction[6];
    x_bit                        = instruction[5];
    multiplicand_register        = instruction[3:0];

    extension_match = (instruction[27:24] == 4'b0001) &&
                      !instruction[20] && instruction[7] &&
                      !instruction[4];
    allocated_operation = instruction[23:21] <= 3'b011;
    decode_match = (condition != 4'b1111) && extension_match &&
                   allocated_operation;
    profile_legal = decode_match && (PROFILE == ARM9_PROFILE_ARM946ES);
    profile_illegal_encoding = decode_match && !profile_legal;

    case (instruction[23:21])
      3'b000: dsp_multiply_kind = ARM9_DSP_MULTIPLY_SMLA_XY;
      3'b001: begin
        dsp_multiply_kind = instruction[5] ? ARM9_DSP_MULTIPLY_SMULW_Y :
                                             ARM9_DSP_MULTIPLY_SMLAW_Y;
      end
      3'b010: dsp_multiply_kind = ARM9_DSP_MULTIPLY_SMLAL_XY;
      default: dsp_multiply_kind = ARM9_DSP_MULTIPLY_SMUL_XY;
    endcase

    uses_accumulator_or_low =
      (dsp_multiply_kind == ARM9_DSP_MULTIPLY_SMLA_XY) ||
      (dsp_multiply_kind == ARM9_DSP_MULTIPLY_SMLAW_Y) ||
      (dsp_multiply_kind == ARM9_DSP_MULTIPLY_SMLAL_XY);
    uses_two_destinations =
      dsp_multiply_kind == ARM9_DSP_MULTIPLY_SMLAL_XY;
    timing_kind = uses_two_destinations ? ARM9_MULTIPLY_DSP_LONG :
                                            ARM9_MULTIPLY_DSP_SHORT;

    sbz_violation = decode_match && !uses_accumulator_or_low &&
                    (accumulator_or_low_register != 4'b0000);
    uses_r15 = (destination_high_register == 4'hf) ||
               (multiplier_register == 4'hf) ||
               (multiplicand_register == 4'hf) ||
               (uses_accumulator_or_low &&
                (accumulator_or_low_register == 4'hf));
    unpredictable_encoding = profile_legal &&
      (sbz_violation || uses_r15 ||
       (uses_two_destinations &&
        (destination_high_register == accumulator_or_low_register)));
    encoding_valid = profile_legal && !unpredictable_encoding;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(encoding_valid && !profile_legal));
    assert (!(profile_legal && profile_illegal_encoding));
    assert (!(unpredictable_encoding && !profile_legal));
  end
`endif
endmodule
