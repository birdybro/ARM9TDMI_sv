module arm9_common_multiply_alu #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  arm9_isa_pkg::arm9_multiply_kind_e multiply_kind,
  input  logic [31:0]                       multiplicand_value,
  input  logic [31:0]                       multiplier_value,
  input  logic [31:0]                       accumulator_low_value,
  input  logic [31:0]                       accumulator_high_value,
  input  logic                              set_flags,
  input  logic                              negative_in,
  input  logic                              zero_in,
  input  logic                              carry_in,
  input  logic                              overflow_in,
  output logic                              operation_supported,
  output logic                              long_result,
  output logic                              accumulate,
  output logic [31:0]                       result_low,
  output logic [31:0]                       result_high,
  output logic                              flags_write_enable,
  output logic                              negative_out,
  output logic                              zero_out,
  output logic                              carry_out,
  output logic                              overflow_out,
  output logic                              carry_unpredictable,
  output logic                              overflow_unpredictable
);
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic signed [31:0] signed_multiplicand;
  logic signed [31:0] signed_multiplier;
  logic signed [63:0] signed_product;
  logic [63:0] unsigned_product;
  logic [63:0] selected_product;
  logic [63:0] accumulator_value;
  logic [63:0] arithmetic_result;

  always_comb begin
    signed_multiplicand = $signed(multiplicand_value);
    signed_multiplier   = $signed(multiplier_value);
    signed_product      = signed_multiplicand * signed_multiplier;
    unsigned_product    = multiplicand_value * multiplier_value;
    accumulator_value   = {accumulator_high_value, accumulator_low_value};

    operation_supported = 1'b1;
    long_result          = 1'b0;
    accumulate           = 1'b0;

    case (multiply_kind)
      ARM9_MULTIPLY_MUL: begin
        selected_product = unsigned_product;
      end
      ARM9_MULTIPLY_MLA: begin
        selected_product = unsigned_product;
        accumulate       = 1'b1;
      end
      ARM9_MULTIPLY_UMULL: begin
        selected_product = unsigned_product;
        long_result      = 1'b1;
      end
      ARM9_MULTIPLY_UMLAL: begin
        selected_product = unsigned_product;
        long_result      = 1'b1;
        accumulate       = 1'b1;
      end
      ARM9_MULTIPLY_SMULL: begin
        selected_product = signed_product;
        long_result      = 1'b1;
      end
      ARM9_MULTIPLY_SMLAL: begin
        selected_product = signed_product;
        long_result      = 1'b1;
        accumulate       = 1'b1;
      end
      default: begin
        selected_product    = '0;
        operation_supported = 1'b0;
      end
    endcase

    if (accumulate) begin
      if (long_result) begin
        arithmetic_result = selected_product + accumulator_value;
      end else begin
        arithmetic_result = {32'b0, selected_product[31:0]} +
                            {32'b0, accumulator_low_value};
      end
    end else begin
      arithmetic_result = selected_product;
    end

    result_low  = arithmetic_result[31:0];
    result_high = long_result ? arithmetic_result[63:32] : 32'b0;

    flags_write_enable     = operation_supported && set_flags;
    negative_out           = negative_in;
    zero_out               = zero_in;
    carry_out              = carry_in;
    overflow_out           = overflow_in;
    carry_unpredictable    = 1'b0;
    overflow_unpredictable = 1'b0;

    if (flags_write_enable) begin
      negative_out = long_result ? result_high[31] : result_low[31];
      zero_out     = long_result ? (arithmetic_result == 64'b0) :
                                   (result_low == 32'b0);

      // ARMv5 and above preserve C and V. ARMv4 and earlier leave C
      // unconstrained for short multiply and both C and V unconstrained
      // for long multiply. Preserve the incoming values as a deterministic
      // implementation choice while exposing those unconstrained outputs.
      if (PROFILE == ARM9_PROFILE_ARM9TDMI) begin
        carry_unpredictable    = 1'b1;
        overflow_unpredictable = long_result;
      end
    end
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(flags_write_enable && !operation_supported));
    assert (!(overflow_unpredictable && !carry_unpredictable));
    assert (!(carry_unpredictable &&
              (PROFILE != ARM9_PROFILE_ARM9TDMI)));
  end
`endif
endmodule
