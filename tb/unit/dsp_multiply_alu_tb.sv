module dsp_multiply_alu_tb;
  import arm9_isa_pkg::*;

  arm9_dsp_multiply_kind_e dsp_multiply_kind;
  logic        x_bit;
  logic        y_bit;
  logic [31:0] multiplicand_value;
  logic [31:0] multiplier_value;
  logic [31:0] accumulator_low_value;
  logic [31:0] accumulator_high_value;
  logic        q_in;
  logic        negative_in;
  logic        zero_in;
  logic        carry_in;
  logic        overflow_in;
  logic        operation_supported;
  logic        long_result;
  logic        accumulate;
  logic [31:0] result_low;
  logic [31:0] result_high;
  logic        q_set;
  logic        q_out;
  logic        negative_out;
  logic        zero_out;
  logic        carry_out;
  logic        overflow_out;
  logic [31:0] random_state;
  int unsigned cases_checked;

  arm9e_dsp_multiply_alu dut (.*);

  function automatic logic [31:0] next_random(input logic [31:0] value);
    logic [31:0] next_value;
    next_value = value;
    next_value ^= next_value << 13;
    next_value ^= next_value >> 17;
    next_value ^= next_value << 5;
    return next_value;
  endfunction

  task automatic apply_and_check;
    logic signed [15:0] reference_left_half;
    logic signed [15:0] reference_right_half;
    logic signed [31:0] reference_half_product;
    logic signed [31:0] reference_word;
    logic signed [47:0] reference_word_product_shifted;
    logic signed [31:0] reference_word_slice;
    logic signed [32:0] reference_sum;
    logic [63:0] reference_long_sum;
    logic [31:0] expected_low;
    logic [31:0] expected_high;
    logic expected_long;
    logic expected_accumulate;
    logic expected_q_set;

    reference_left_half = x_bit ?
      $signed(multiplicand_value[31:16]) :
      $signed(multiplicand_value[15:0]);
    reference_right_half = y_bit ?
      $signed(multiplier_value[31:16]) :
      $signed(multiplier_value[15:0]);
    reference_half_product = reference_left_half * reference_right_half;
    reference_word = $signed(multiplicand_value);
    reference_word_product_shifted =
      (reference_word * reference_right_half) >>> 16;
    reference_word_slice = reference_word_product_shifted[31:0];
    assert (reference_word_product_shifted[47:32] ==
            {16{reference_word_product_shifted[31]}});

    expected_low        = 32'b0;
    expected_high       = 32'b0;
    expected_long       = 1'b0;
    expected_accumulate = 1'b0;
    expected_q_set      = 1'b0;
    reference_sum       = '0;
    reference_long_sum  = '0;

    case (dsp_multiply_kind)
      ARM9_DSP_MULTIPLY_SMLA_XY: begin
        expected_accumulate = 1'b1;
        reference_sum = $signed({reference_half_product[31],
                                 reference_half_product}) +
                        $signed({accumulator_low_value[31],
                                 accumulator_low_value});
        expected_low   = reference_sum[31:0];
        expected_q_set = reference_sum[32] != reference_sum[31];
      end
      ARM9_DSP_MULTIPLY_SMLAW_Y: begin
        expected_accumulate = 1'b1;
        reference_sum = $signed({reference_word_slice[31],
                                 reference_word_slice}) +
                        $signed({accumulator_low_value[31],
                                 accumulator_low_value});
        expected_low   = reference_sum[31:0];
        expected_q_set = reference_sum[32] != reference_sum[31];
      end
      ARM9_DSP_MULTIPLY_SMULW_Y: expected_low = reference_word_slice;
      ARM9_DSP_MULTIPLY_SMLAL_XY: begin
        expected_long       = 1'b1;
        expected_accumulate = 1'b1;
        reference_long_sum =
          {accumulator_high_value, accumulator_low_value} +
          {{32{reference_half_product[31]}}, reference_half_product};
        expected_low  = reference_long_sum[31:0];
        expected_high = reference_long_sum[63:32];
      end
      default: expected_low = reference_half_product;
    endcase

    #1ps;
    assert (operation_supported);
    assert (long_result == expected_long);
    assert (accumulate == expected_accumulate);
    assert (result_low == expected_low);
    assert (result_high == expected_high);
    assert (q_set == expected_q_set);
    assert (q_out == (q_in || expected_q_set));
    assert (negative_out == negative_in);
    assert (zero_out == zero_in);
    assert (carry_out == carry_in);
    assert (overflow_out == overflow_in);
    cases_checked++;
  endtask

  initial begin
    logic [31:0] boundary_values [0:9];

    boundary_values[0] = 32'h0000_0000;
    boundary_values[1] = 32'h0001_0001;
    boundary_values[2] = 32'h7fff_7fff;
    boundary_values[3] = 32'h8000_8000;
    boundary_values[4] = 32'hffff_ffff;
    boundary_values[5] = 32'h7fff_8000;
    boundary_values[6] = 32'h8000_7fff;
    boundary_values[7] = 32'h1234_5678;
    boundary_values[8] = 32'h8765_4321;
    boundary_values[9] = 32'ha5a5_5a5a;

    dsp_multiply_kind       = ARM9_DSP_MULTIPLY_SMLA_XY;
    x_bit                   = 1'b0;
    y_bit                   = 1'b0;
    multiplicand_value      = '0;
    multiplier_value        = '0;
    accumulator_low_value   = '0;
    accumulator_high_value  = '0;
    q_in                    = 1'b0;
    negative_in             = 1'b0;
    zero_in                 = 1'b0;
    carry_in                = 1'b0;
    overflow_in             = 1'b0;
    random_state            = 32'h5eed_946e;
    cases_checked           = 0;

    // REQ: ARM946ES-DSP-MULTIPLY-ARITH-001
    // REQ: ARM946ES-DSP-MULTIPLY-Q-001
    for (int unsigned left = 0; left < 10; left++) begin
      for (int unsigned right = 0; right < 10; right++) begin
        multiplicand_value     = boundary_values[left];
        multiplier_value       = boundary_values[right];
        accumulator_low_value  = boundary_values[(left + 1) % 10];
        accumulator_high_value = boundary_values[(right + 3) % 10];
        for (int unsigned kind = 0; kind < 5; kind++) begin
          dsp_multiply_kind = arm9_dsp_multiply_kind_e'(kind[2:0]);
          for (int unsigned selector = 0; selector < 4; selector++) begin
            x_bit = selector[0];
            y_bit = selector[1];
            q_in  = left[0] ^ right[0];
            negative_in = left[0];
            zero_in     = right[0];
            carry_in    = selector[0];
            overflow_in = selector[1];
            apply_and_check();
          end
        end
      end
    end

    for (int unsigned random_case = 0; random_case < 2_000;
         random_case++) begin
      random_state = next_random(random_state);
      multiplicand_value = random_state;
      random_state = next_random(random_state);
      multiplier_value = random_state;
      random_state = next_random(random_state);
      accumulator_low_value = random_state;
      random_state = next_random(random_state);
      accumulator_high_value = random_state;
      dsp_multiply_kind =
        arm9_dsp_multiply_kind_e'(random_case % 5);
      x_bit = random_case[0];
      y_bit = random_case[1];
      q_in  = random_case[2];
      negative_in = random_case[3];
      zero_in     = random_case[4];
      carry_in    = random_case[5];
      overflow_in = random_case[6];
      apply_and_check();
    end

    // Explicit positive and negative overflow, and sticky-Q cases.
    dsp_multiply_kind      = ARM9_DSP_MULTIPLY_SMLA_XY;
    x_bit                  = 1'b0;
    y_bit                  = 1'b0;
    multiplicand_value     = 32'h0000_7fff;
    multiplier_value       = 32'h0000_7fff;
    accumulator_low_value  = 32'h7fff_ffff;
    accumulator_high_value = '0;
    q_in                   = 1'b0;
    apply_and_check();
    assert (q_set && q_out);

    multiplicand_value    = 32'h0000_8000;
    multiplier_value      = 32'h0000_7fff;
    accumulator_low_value = 32'h8000_0000;
    apply_and_check();
    assert (q_set && q_out);

    accumulator_low_value = 32'b0;
    q_in                  = 1'b1;
    apply_and_check();
    assert (!q_set && q_out);

    dsp_multiply_kind     = ARM9_DSP_MULTIPLY_SMULW_Y;
    y_bit                = 1'b0;
    multiplier_value     = 32'h0000_0001;
    multiplicand_value   = 32'h0001_0000;
    q_in                  = 1'b0;
    apply_and_check();
    assert (result_low == 32'h0000_0001);

    multiplicand_value = 32'hffff_0000;
    apply_and_check();
    assert (result_low == 32'hffff_ffff);

    dsp_multiply_kind = arm9_dsp_multiply_kind_e'(3'b111);
    q_in              = 1'b0;
    #1ps;
    assert (!operation_supported && !q_set && !q_out);
    cases_checked++;

    assert (cases_checked == 4_006);
    $display("PASS ARM9E-S DSP multiply arithmetic (4006 cases)");
    $finish;
  end
endmodule
