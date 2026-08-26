module arm9e_dsp_multiply_alu (
  input  arm9_isa_pkg::arm9_dsp_multiply_kind_e dsp_multiply_kind,
  input  logic                                  x_bit,
  input  logic                                  y_bit,
  input  logic [31:0]                           multiplicand_value,
  input  logic [31:0]                           multiplier_value,
  input  logic [31:0]                           accumulator_low_value,
  input  logic [31:0]                           accumulator_high_value,
  input  logic                                  q_in,
  input  logic                                  negative_in,
  input  logic                                  zero_in,
  input  logic                                  carry_in,
  input  logic                                  overflow_in,
  output logic                                  operation_supported,
  output logic                                  long_result,
  output logic                                  accumulate,
  output logic [31:0]                           result_low,
  output logic [31:0]                           result_high,
  output logic                                  q_set,
  output logic                                  q_out,
  output logic                                  negative_out,
  output logic                                  zero_out,
  output logic                                  carry_out,
  output logic                                  overflow_out
);
  import arm9_isa_pkg::*;

  logic signed [15:0] selected_multiplicand_half;
  logic signed [15:0] selected_multiplier_half;
  logic signed [31:0] halfword_product;
  logic signed [31:0] signed_multiplicand;
  logic signed [47:0] word_halfword_product_shifted;
  logic signed [31:0] word_product_slice;
  logic signed [32:0] accumulate_sum_wide;
  logic [63:0] long_accumulator;
  logic [63:0] long_product;
  logic [63:0] long_sum;

  always_comb begin
    selected_multiplicand_half = x_bit ?
      $signed(multiplicand_value[31:16]) :
      $signed(multiplicand_value[15:0]);
    selected_multiplier_half = y_bit ?
      $signed(multiplier_value[31:16]) :
      $signed(multiplier_value[15:0]);
    halfword_product = selected_multiplicand_half *
                       selected_multiplier_half;

    signed_multiplicand = $signed(multiplicand_value);
    word_halfword_product_shifted =
      (signed_multiplicand * selected_multiplier_half) >>> 16;
    word_product_slice = word_halfword_product_shifted[31:0];
    long_accumulator = {accumulator_high_value, accumulator_low_value};
    long_product = {{32{halfword_product[31]}}, halfword_product};
    long_sum = long_accumulator + long_product;

    operation_supported = 1'b1;
    long_result          = 1'b0;
    accumulate           = 1'b0;
    result_low           = 32'b0;
    result_high          = 32'b0;
    accumulate_sum_wide  = '0;
    q_set                = 1'b0;

    case (dsp_multiply_kind)
      ARM9_DSP_MULTIPLY_SMLA_XY: begin
        accumulate          = 1'b1;
        accumulate_sum_wide = $signed({halfword_product[31],
                                       halfword_product}) +
                              $signed({accumulator_low_value[31],
                                       accumulator_low_value});
        result_low = accumulate_sum_wide[31:0];
        q_set      = accumulate_sum_wide[32] != accumulate_sum_wide[31];
      end
      ARM9_DSP_MULTIPLY_SMLAW_Y: begin
        accumulate          = 1'b1;
        accumulate_sum_wide = $signed({word_product_slice[31],
                                       word_product_slice}) +
                              $signed({accumulator_low_value[31],
                                       accumulator_low_value});
        result_low = accumulate_sum_wide[31:0];
        q_set      = accumulate_sum_wide[32] != accumulate_sum_wide[31];
      end
      ARM9_DSP_MULTIPLY_SMULW_Y: begin
        result_low = word_product_slice;
      end
      ARM9_DSP_MULTIPLY_SMLAL_XY: begin
        long_result = 1'b1;
        accumulate  = 1'b1;
        result_low  = long_sum[31:0];
        result_high = long_sum[63:32];
      end
      ARM9_DSP_MULTIPLY_SMUL_XY: begin
        result_low = halfword_product;
      end
      default: begin
        operation_supported = 1'b0;
      end
    endcase

    q_out = q_in || q_set;
    negative_out = negative_in;
    zero_out     = zero_in;
    carry_out    = carry_in;
    overflow_out = overflow_in;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(q_set && !operation_supported));
    assert (!(q_in && !q_out));
    assert (!(long_result &&
              (dsp_multiply_kind != ARM9_DSP_MULTIPLY_SMLAL_XY)));
    assert (word_halfword_product_shifted[47:32] ==
            {16{word_halfword_product_shifted[31]}});
  end
`endif
endmodule
