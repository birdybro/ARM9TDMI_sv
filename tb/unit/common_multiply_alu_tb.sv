module common_multiply_alu_tb;
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic [31:0] multiplicand_value;
  logic [31:0] multiplier_value;
  logic [31:0] accumulator_low_value;
  logic [31:0] accumulator_high_value;
  logic        set_flags;
  logic        negative_in;
  logic        zero_in;
  logic        carry_in;
  logic        overflow_in;
  arm9_multiply_kind_e multiply_kind;

  logic        tdmi_operation_supported;
  logic        tdmi_long_result;
  logic        tdmi_accumulate;
  logic [31:0] tdmi_result_low;
  logic [31:0] tdmi_result_high;
  logic        tdmi_flags_write_enable;
  logic        tdmi_negative_out;
  logic        tdmi_zero_out;
  logic        tdmi_carry_out;
  logic        tdmi_overflow_out;
  logic        tdmi_carry_unpredictable;
  logic        tdmi_overflow_unpredictable;

  logic        arm946_operation_supported;
  logic        arm946_long_result;
  logic        arm946_accumulate;
  logic [31:0] arm946_result_low;
  logic [31:0] arm946_result_high;
  logic        arm946_flags_write_enable;
  logic        arm946_negative_out;
  logic        arm946_zero_out;
  logic        arm946_carry_out;
  logic        arm946_overflow_out;
  logic        arm946_carry_unpredictable;
  logic        arm946_overflow_unpredictable;
  int unsigned cases_checked;
  logic [31:0] random_state;

  arm9_common_multiply_alu #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .operation_supported(tdmi_operation_supported),
    .long_result(tdmi_long_result),
    .accumulate(tdmi_accumulate),
    .result_low(tdmi_result_low),
    .result_high(tdmi_result_high),
    .flags_write_enable(tdmi_flags_write_enable),
    .negative_out(tdmi_negative_out),
    .zero_out(tdmi_zero_out),
    .carry_out(tdmi_carry_out),
    .overflow_out(tdmi_overflow_out),
    .carry_unpredictable(tdmi_carry_unpredictable),
    .overflow_unpredictable(tdmi_overflow_unpredictable),
    .*
  );

  arm9_common_multiply_alu #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .operation_supported(arm946_operation_supported),
    .long_result(arm946_long_result),
    .accumulate(arm946_accumulate),
    .result_low(arm946_result_low),
    .result_high(arm946_result_high),
    .flags_write_enable(arm946_flags_write_enable),
    .negative_out(arm946_negative_out),
    .zero_out(arm946_zero_out),
    .carry_out(arm946_carry_out),
    .overflow_out(arm946_overflow_out),
    .carry_unpredictable(arm946_carry_unpredictable),
    .overflow_unpredictable(arm946_overflow_unpredictable),
    .*
  );

  function automatic logic [31:0] next_random(input logic [31:0] value);
    logic [31:0] next_value;
    next_value = value;
    next_value ^= next_value << 13;
    next_value ^= next_value >> 17;
    next_value ^= next_value << 5;
    return next_value;
  endfunction

  task automatic apply_and_check;
    logic signed [31:0] reference_multiplicand;
    logic signed [31:0] reference_multiplier;
    logic signed [63:0] reference_signed_product;
    logic [63:0] reference_unsigned_product;
    logic [63:0] reference_product;
    logic [63:0] reference_result;
    logic reference_long;
    logic reference_accumulate;

    reference_multiplicand   = $signed(multiplicand_value);
    reference_multiplier     = $signed(multiplier_value);
    reference_signed_product = reference_multiplicand * reference_multiplier;
    reference_unsigned_product = multiplicand_value * multiplier_value;
    reference_long = (multiply_kind == ARM9_MULTIPLY_UMULL) ||
                     (multiply_kind == ARM9_MULTIPLY_UMLAL) ||
                     (multiply_kind == ARM9_MULTIPLY_SMULL) ||
                     (multiply_kind == ARM9_MULTIPLY_SMLAL);
    reference_accumulate = (multiply_kind == ARM9_MULTIPLY_MLA) ||
                           (multiply_kind == ARM9_MULTIPLY_UMLAL) ||
                           (multiply_kind == ARM9_MULTIPLY_SMLAL);
    reference_product = ((multiply_kind == ARM9_MULTIPLY_SMULL) ||
                         (multiply_kind == ARM9_MULTIPLY_SMLAL)) ?
                        reference_signed_product :
                        reference_unsigned_product;
    if (reference_accumulate) begin
      if (reference_long) begin
        reference_result = reference_product +
                           {accumulator_high_value,
                            accumulator_low_value};
      end else begin
        reference_result = {32'b0, reference_product[31:0]} +
                           {32'b0, accumulator_low_value};
      end
    end else begin
      reference_result = reference_product;
    end

    #1ps;
    assert (tdmi_operation_supported && arm946_operation_supported);
    assert (tdmi_long_result == reference_long);
    assert (arm946_long_result == reference_long);
    assert (tdmi_accumulate == reference_accumulate);
    assert (arm946_accumulate == reference_accumulate);
    assert (tdmi_result_low == reference_result[31:0]);
    assert (arm946_result_low == reference_result[31:0]);
    assert (tdmi_result_high ==
            (reference_long ? reference_result[63:32] : 32'b0));
    assert (arm946_result_high == tdmi_result_high);
    assert (tdmi_flags_write_enable == set_flags);
    assert (arm946_flags_write_enable == set_flags);
    assert (tdmi_carry_out == carry_in && arm946_carry_out == carry_in);
    assert (tdmi_overflow_out == overflow_in &&
            arm946_overflow_out == overflow_in);

    if (set_flags) begin
      assert (tdmi_negative_out ==
              (reference_long ? reference_result[63] :
                                reference_result[31]));
      assert (tdmi_zero_out ==
              (reference_long ? (reference_result == 64'b0) :
                                (reference_result[31:0] == 32'b0)));
      assert (arm946_negative_out == tdmi_negative_out);
      assert (arm946_zero_out == tdmi_zero_out);
      assert (tdmi_carry_unpredictable);
      assert (tdmi_overflow_unpredictable == reference_long);
      assert (!arm946_carry_unpredictable);
      assert (!arm946_overflow_unpredictable);
    end else begin
      assert (tdmi_negative_out == negative_in);
      assert (tdmi_zero_out == zero_in);
      assert (arm946_negative_out == negative_in);
      assert (arm946_zero_out == zero_in);
      assert (!tdmi_carry_unpredictable);
      assert (!tdmi_overflow_unpredictable);
      assert (!arm946_carry_unpredictable);
      assert (!arm946_overflow_unpredictable);
    end
    cases_checked++;
  endtask

  initial begin
    logic [31:0] boundary_values [0:9];

    boundary_values[0] = 32'h0000_0000;
    boundary_values[1] = 32'h0000_0001;
    boundary_values[2] = 32'hffff_ffff;
    boundary_values[3] = 32'h7fff_ffff;
    boundary_values[4] = 32'h8000_0000;
    boundary_values[5] = 32'h0000_ffff;
    boundary_values[6] = 32'hffff_0000;
    boundary_values[7] = 32'h1234_5678;
    boundary_values[8] = 32'h8765_4321;
    boundary_values[9] = 32'ha5a5_5a5a;

    multiplicand_value       = '0;
    multiplier_value         = '0;
    accumulator_low_value    = '0;
    accumulator_high_value   = '0;
    multiply_kind            = ARM9_MULTIPLY_MUL;
    set_flags                = 1'b0;
    negative_in              = 1'b1;
    zero_in                  = 1'b0;
    carry_in                 = 1'b1;
    overflow_in              = 1'b0;
    cases_checked            = 0;
    random_state             = 32'h9469_001d;

    // REQ: COMMON-ARM-MULTIPLY-ARITH-001
    // REQ: COMMON-ARM-MULTIPLY-FLAGS-001
    for (int unsigned left_index = 0; left_index < 10; left_index++) begin
      for (int unsigned right_index = 0; right_index < 10; right_index++) begin
        multiplicand_value     = boundary_values[left_index];
        multiplier_value       = boundary_values[right_index];
        accumulator_low_value  = boundary_values[(left_index + 3) % 10];
        accumulator_high_value = boundary_values[(right_index + 7) % 10];
        for (int unsigned kind_index = 0; kind_index < 6; kind_index++) begin
          multiply_kind = arm9_multiply_kind_e'(kind_index[2:0]);
          for (int unsigned flags = 0; flags < 2; flags++) begin
            set_flags   = flags[0];
            negative_in = left_index[0];
            zero_in     = right_index[0];
            carry_in    = left_index[0] ^ right_index[0];
            overflow_in = left_index[0] == right_index[0];
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
      multiply_kind = arm9_multiply_kind_e'(random_case % 6);
      set_flags     = random_case[0];
      negative_in   = random_case[1];
      zero_in       = random_case[2];
      carry_in      = random_case[3];
      overflow_in   = random_case[4];
      apply_and_check();
    end

    multiply_kind = ARM9_MULTIPLY_DSP_SHORT;
    #1ps;
    assert (!tdmi_operation_supported && !arm946_operation_supported);
    assert (!tdmi_flags_write_enable && !arm946_flags_write_enable);
    cases_checked++;

    assert (cases_checked == 3_201);
    $display("PASS common ARM multiply arithmetic (3201 cases/profile)");
    $finish;
  end
endmodule
