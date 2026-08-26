module common_multiply_execute_tb;
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic [31:0] instruction;
  logic [31:0] multiplicand_value;
  logic [31:0] multiplier_value;
  logic [31:0] accumulator_low_value;
  logic [31:0] accumulator_high_value;
  logic        negative_in;
  logic        zero_in;
  logic        carry_in;
  logic        overflow_in;

  logic        tdmi_decode_match;
  logic        tdmi_encoding_valid;
  logic        tdmi_unpredictable_encoding;
  logic        tdmi_condition_passed;
  logic        tdmi_unconditional_space;
  logic        tdmi_execute_valid;
  arm9_multiply_kind_e tdmi_multiply_kind;
  logic [3:0]  tdmi_destination_high_register;
  logic [3:0]  tdmi_destination_low_register;
  logic [3:0]  tdmi_multiplier_register;
  logic [3:0]  tdmi_multiplicand_register;
  logic        tdmi_long_result;
  logic        tdmi_destination_high_write_enable;
  logic [31:0] tdmi_destination_high_write_data;
  logic        tdmi_destination_low_write_enable;
  logic [31:0] tdmi_destination_low_write_data;
  logic        tdmi_flags_write_enable;
  logic        tdmi_negative_out;
  logic        tdmi_zero_out;
  logic        tdmi_carry_out;
  logic        tdmi_overflow_out;
  logic        tdmi_carry_unpredictable;
  logic        tdmi_overflow_unpredictable;

  logic        arm946_decode_match;
  logic        arm946_encoding_valid;
  logic        arm946_unpredictable_encoding;
  logic        arm946_condition_passed;
  logic        arm946_unconditional_space;
  logic        arm946_execute_valid;
  arm9_multiply_kind_e arm946_multiply_kind;
  logic [3:0]  arm946_destination_high_register;
  logic [3:0]  arm946_destination_low_register;
  logic [3:0]  arm946_multiplier_register;
  logic [3:0]  arm946_multiplicand_register;
  logic        arm946_long_result;
  logic        arm946_destination_high_write_enable;
  logic [31:0] arm946_destination_high_write_data;
  logic        arm946_destination_low_write_enable;
  logic [31:0] arm946_destination_low_write_data;
  logic        arm946_flags_write_enable;
  logic        arm946_negative_out;
  logic        arm946_zero_out;
  logic        arm946_carry_out;
  logic        arm946_overflow_out;
  logic        arm946_carry_unpredictable;
  logic        arm946_overflow_unpredictable;
  int unsigned cases_checked;

  arm9_common_multiply_execute #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .decode_match(tdmi_decode_match),
    .encoding_valid(tdmi_encoding_valid),
    .unpredictable_encoding(tdmi_unpredictable_encoding),
    .condition_passed(tdmi_condition_passed),
    .unconditional_space(tdmi_unconditional_space),
    .execute_valid(tdmi_execute_valid),
    .multiply_kind(tdmi_multiply_kind),
    .destination_high_register(tdmi_destination_high_register),
    .destination_low_register(tdmi_destination_low_register),
    .multiplier_register(tdmi_multiplier_register),
    .multiplicand_register(tdmi_multiplicand_register),
    .long_result(tdmi_long_result),
    .destination_high_write_enable(tdmi_destination_high_write_enable),
    .destination_high_write_data(tdmi_destination_high_write_data),
    .destination_low_write_enable(tdmi_destination_low_write_enable),
    .destination_low_write_data(tdmi_destination_low_write_data),
    .flags_write_enable(tdmi_flags_write_enable),
    .negative_out(tdmi_negative_out),
    .zero_out(tdmi_zero_out),
    .carry_out(tdmi_carry_out),
    .overflow_out(tdmi_overflow_out),
    .carry_unpredictable(tdmi_carry_unpredictable),
    .overflow_unpredictable(tdmi_overflow_unpredictable),
    .*
  );

  arm9_common_multiply_execute #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .decode_match(arm946_decode_match),
    .encoding_valid(arm946_encoding_valid),
    .unpredictable_encoding(arm946_unpredictable_encoding),
    .condition_passed(arm946_condition_passed),
    .unconditional_space(arm946_unconditional_space),
    .execute_valid(arm946_execute_valid),
    .multiply_kind(arm946_multiply_kind),
    .destination_high_register(arm946_destination_high_register),
    .destination_low_register(arm946_destination_low_register),
    .multiplier_register(arm946_multiplier_register),
    .multiplicand_register(arm946_multiplicand_register),
    .long_result(arm946_long_result),
    .destination_high_write_enable(arm946_destination_high_write_enable),
    .destination_high_write_data(arm946_destination_high_write_data),
    .destination_low_write_enable(arm946_destination_low_write_enable),
    .destination_low_write_data(arm946_destination_low_write_data),
    .flags_write_enable(arm946_flags_write_enable),
    .negative_out(arm946_negative_out),
    .zero_out(arm946_zero_out),
    .carry_out(arm946_carry_out),
    .overflow_out(arm946_overflow_out),
    .carry_unpredictable(arm946_carry_unpredictable),
    .overflow_unpredictable(arm946_overflow_unpredictable),
    .*
  );

  function automatic logic reference_condition(
    input logic [3:0] condition,
    input logic n,
    input logic z,
    input logic c,
    input logic v
  );
    case (condition)
      4'h0: return z;
      4'h1: return !z;
      4'h2: return c;
      4'h3: return !c;
      4'h4: return n;
      4'h5: return !n;
      4'h6: return v;
      4'h7: return !v;
      4'h8: return c && !z;
      4'h9: return !c || z;
      4'ha: return n == v;
      4'hb: return n != v;
      4'hc: return !z && (n == v);
      4'hd: return z || (n != v);
      4'he: return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  task automatic encode_kind(
    input arm9_multiply_kind_e kind,
    input logic update_flags
  );
    instruction = 32'he000_0090;
    instruction[20]    = update_flags;
    instruction[19:16] = 4'h1;
    instruction[15:12] = 4'h2;
    instruction[11:8]  = 4'h3;
    instruction[3:0]   = 4'h4;
    case (kind)
      ARM9_MULTIPLY_MUL: begin
        instruction[15:12] = 4'h0;
      end
      ARM9_MULTIPLY_MLA: begin
        instruction[21] = 1'b1;
      end
      ARM9_MULTIPLY_UMULL: begin
        instruction[23] = 1'b1;
      end
      ARM9_MULTIPLY_UMLAL: begin
        instruction[23] = 1'b1;
        instruction[21] = 1'b1;
      end
      ARM9_MULTIPLY_SMULL: begin
        instruction[23] = 1'b1;
        instruction[22] = 1'b1;
      end
      ARM9_MULTIPLY_SMLAL: begin
        instruction[23] = 1'b1;
        instruction[22] = 1'b1;
        instruction[21] = 1'b1;
      end
      default: instruction = '0;
    endcase
  endtask

  initial begin
    logic expected_condition;

    instruction              = '0;
    multiplicand_value       = 32'hffff_fffd;
    multiplier_value         = 32'h0000_0007;
    accumulator_low_value    = 32'h0000_0010;
    accumulator_high_value   = 32'hffff_ffff;
    negative_in              = 1'b0;
    zero_in                  = 1'b0;
    carry_in                 = 1'b1;
    overflow_in              = 1'b0;
    cases_checked            = 0;

    // REQ: COMMON-ARM-MULTIPLY-EXECUTE-001
    for (int unsigned kind = 0; kind < 6; kind++) begin
      for (int unsigned condition = 0; condition < 15; condition++) begin
        for (int unsigned update_flags = 0; update_flags < 2;
             update_flags++) begin
          for (int unsigned flags = 0; flags < 16; flags++) begin
            encode_kind(
              arm9_multiply_kind_e'(kind[2:0]), update_flags[0]
            );
            instruction[31:28] = condition[3:0];
            negative_in = flags[3];
            zero_in     = flags[2];
            carry_in    = flags[1];
            overflow_in = flags[0];
            expected_condition = reference_condition(
              condition[3:0], negative_in, zero_in, carry_in, overflow_in
            );
            #1ps;

            assert (tdmi_decode_match && tdmi_encoding_valid);
            assert (!tdmi_unpredictable_encoding);
            assert (arm946_decode_match && arm946_encoding_valid);
            assert (!arm946_unpredictable_encoding);
            assert (tdmi_multiply_kind ==
                    arm9_multiply_kind_e'(kind[2:0]));
            assert (arm946_multiply_kind == tdmi_multiply_kind);
            assert (tdmi_destination_high_register == 4'h1);
            assert (arm946_destination_high_register == 4'h1);
            assert (tdmi_destination_low_register ==
                    ((kind == 0) ? 4'h0 : 4'h2));
            assert (arm946_destination_low_register ==
                    tdmi_destination_low_register);
            assert (tdmi_multiplier_register == 4'h3);
            assert (arm946_multiplier_register == 4'h3);
            assert (tdmi_multiplicand_register == 4'h4);
            assert (arm946_multiplicand_register == 4'h4);
            assert (tdmi_condition_passed == expected_condition);
            assert (arm946_condition_passed == expected_condition);
            assert (!tdmi_unconditional_space &&
                    !arm946_unconditional_space);
            assert (tdmi_execute_valid == expected_condition);
            assert (arm946_execute_valid == expected_condition);
            assert (tdmi_destination_high_write_enable ==
                    expected_condition);
            assert (arm946_destination_high_write_enable ==
                    expected_condition);
            assert (tdmi_destination_low_write_enable ==
                    (expected_condition && tdmi_long_result));
            assert (arm946_long_result == tdmi_long_result);
            assert (arm946_destination_low_write_enable ==
                    tdmi_destination_low_write_enable);
            assert (tdmi_flags_write_enable ==
                    (expected_condition && update_flags[0]));
            assert (arm946_flags_write_enable == tdmi_flags_write_enable);
            assert (tdmi_destination_high_write_data ==
                    arm946_destination_high_write_data);
            assert (tdmi_destination_low_write_data ==
                    arm946_destination_low_write_data);
            assert (tdmi_negative_out == arm946_negative_out);
            assert (tdmi_zero_out == arm946_zero_out);
            assert (tdmi_carry_out == carry_in);
            assert (arm946_carry_out == carry_in);
            assert (tdmi_overflow_out == overflow_in);
            assert (arm946_overflow_out == overflow_in);
            assert (arm946_carry_unpredictable == 1'b0);
            assert (arm946_overflow_unpredictable == 1'b0);
            assert (tdmi_carry_unpredictable ==
                    (expected_condition && update_flags[0]));
            assert (tdmi_overflow_unpredictable ==
                    (expected_condition && update_flags[0] &&
                     tdmi_long_result));
            cases_checked++;
          end
        end
      end
    end

    // Invalid encodings and failed conditions must never write state.
    encode_kind(ARM9_MULTIPLY_MUL, 1'b1);
    instruction[19:16] = 4'hf;
    #1ps;
    assert (tdmi_decode_match && tdmi_unpredictable_encoding);
    assert (!tdmi_encoding_valid && !tdmi_execute_valid);
    assert (!tdmi_destination_high_write_enable);
    assert (!tdmi_destination_low_write_enable);
    assert (!tdmi_flags_write_enable);
    assert (!tdmi_carry_unpredictable && !tdmi_overflow_unpredictable);
    cases_checked++;

    encode_kind(ARM9_MULTIPLY_MUL, 1'b0);
    instruction[31:28] = 4'hf;
    #1ps;
    assert (!tdmi_decode_match && !tdmi_encoding_valid);
    assert (!tdmi_execute_valid && !tdmi_destination_high_write_enable);
    assert (tdmi_unconditional_space && arm946_unconditional_space);
    cases_checked++;

    assert (cases_checked == 2_882);
    $display("PASS integrated common ARM multiply execute (2882 cases/profile)");
    $finish;
  end
endmodule
