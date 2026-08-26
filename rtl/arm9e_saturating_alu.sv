module arm9e_saturating_alu (
  input  arm9_isa_pkg::arm9_saturating_kind_e saturating_kind,
  input  logic [31:0] first_operand,
  input  logic [31:0] second_operand,
  input  logic        q_in,
  input  logic        negative_in,
  input  logic        zero_in,
  input  logic        carry_in,
  input  logic        overflow_in,
  output logic [31:0] result,
  output logic        q_set,
  output logic        q_out,
  output logic        negative_out,
  output logic        zero_out,
  output logic        carry_out,
  output logic        overflow_out
);
  import arm9_isa_pkg::*;

  logic signed [32:0] first_extended;
  logic signed [32:0] second_extended;
  logic signed [32:0] doubled_wide;
  logic signed [32:0] second_stage_extended;
  logic signed [32:0] result_wide;
  logic [31:0] doubled_saturated;
  logic double_saturated;
  logic result_saturated;
  logic doubles_second_operand;
  logic subtracts_second_operand;

  function automatic logic signed_value_saturates(
    input logic signed [32:0] value
  );
    return (value > $signed({1'b0, 32'h7fff_ffff})) ||
           (value < $signed({1'b1, 32'h8000_0000}));
  endfunction

  function automatic logic [31:0] signed_saturate(
    input logic signed [32:0] value
  );
    if (value > $signed({1'b0, 32'h7fff_ffff})) begin
      return 32'h7fff_ffff;
    end
    if (value < $signed({1'b1, 32'h8000_0000})) begin
      return 32'h8000_0000;
    end
    return value[31:0];
  endfunction

  always_comb begin
    first_extended  = $signed({first_operand[31], first_operand});
    second_extended = $signed({second_operand[31], second_operand});
    doubled_wide    = second_extended <<< 1;
    doubled_saturated = signed_saturate(doubled_wide);
    double_saturated  = signed_value_saturates(doubled_wide);

    doubles_second_operand = saturating_kind[1];
    subtracts_second_operand = saturating_kind[0];
    if (doubles_second_operand) begin
      second_stage_extended =
        $signed({doubled_saturated[31], doubled_saturated});
    end else begin
      second_stage_extended = second_extended;
      double_saturated = 1'b0;
    end

    if (subtracts_second_operand) begin
      result_wide = first_extended - second_stage_extended;
    end else begin
      result_wide = first_extended + second_stage_extended;
    end
    result_saturated = signed_value_saturates(result_wide);
    result            = signed_saturate(result_wide);
    q_set             = double_saturated || result_saturated;
    q_out             = q_in || q_set;
    negative_out      = negative_in;
    zero_out          = zero_in;
    carry_out         = carry_in;
    overflow_out      = overflow_in;
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (q_out == (q_in || q_set));
    assert (negative_out == negative_in);
    assert (zero_out == zero_in);
    assert (carry_out == carry_in);
    assert (overflow_out == overflow_in);
    if (!doubles_second_operand) begin
      assert (!double_saturated);
    end
  end
`endif
endmodule
