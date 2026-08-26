module dsp_multiply_execute_tb;
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic [31:0] instruction;
  logic [31:0] multiplicand_value;
  logic [31:0] multiplier_value;
  logic [31:0] accumulator_low_value;
  logic [31:0] accumulator_high_value;
  logic        q_in;
  logic        negative_in;
  logic        zero_in;
  logic        carry_in;
  logic        overflow_in;

  logic tdmi_decode_match;
  logic tdmi_profile_legal;
  logic tdmi_profile_illegal_encoding;
  logic tdmi_encoding_valid;
  logic tdmi_unpredictable_encoding;
  logic tdmi_condition_passed;
  logic tdmi_unconditional_space;
  logic tdmi_execute_valid;
  arm9_dsp_multiply_kind_e tdmi_dsp_multiply_kind;
  arm9_multiply_kind_e tdmi_timing_kind;
  logic [3:0] tdmi_destination_high_register;
  logic [3:0] tdmi_accumulator_or_low_register;
  logic [3:0] tdmi_multiplier_register;
  logic [3:0] tdmi_multiplicand_register;
  logic tdmi_long_result;
  logic tdmi_destination_high_write_enable;
  logic [31:0] tdmi_destination_high_write_data;
  logic tdmi_destination_low_write_enable;
  logic [31:0] tdmi_destination_low_write_data;
  logic tdmi_q_set_request;
  logic tdmi_q_out;
  logic tdmi_negative_out;
  logic tdmi_zero_out;
  logic tdmi_carry_out;
  logic tdmi_overflow_out;

  logic arm946_decode_match;
  logic arm946_profile_legal;
  logic arm946_profile_illegal_encoding;
  logic arm946_encoding_valid;
  logic arm946_unpredictable_encoding;
  logic arm946_condition_passed;
  logic arm946_unconditional_space;
  logic arm946_execute_valid;
  arm9_dsp_multiply_kind_e arm946_dsp_multiply_kind;
  arm9_multiply_kind_e arm946_timing_kind;
  logic [3:0] arm946_destination_high_register;
  logic [3:0] arm946_accumulator_or_low_register;
  logic [3:0] arm946_multiplier_register;
  logic [3:0] arm946_multiplicand_register;
  logic arm946_long_result;
  logic arm946_destination_high_write_enable;
  logic [31:0] arm946_destination_high_write_data;
  logic arm946_destination_low_write_enable;
  logic [31:0] arm946_destination_low_write_data;
  logic arm946_q_set_request;
  logic arm946_q_out;
  logic arm946_negative_out;
  logic arm946_zero_out;
  logic arm946_carry_out;
  logic arm946_overflow_out;
  int unsigned cases_checked;

  arm9_dsp_multiply_execute #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .decode_match(tdmi_decode_match),
    .profile_legal(tdmi_profile_legal),
    .profile_illegal_encoding(tdmi_profile_illegal_encoding),
    .encoding_valid(tdmi_encoding_valid),
    .unpredictable_encoding(tdmi_unpredictable_encoding),
    .condition_passed(tdmi_condition_passed),
    .unconditional_space(tdmi_unconditional_space),
    .execute_valid(tdmi_execute_valid),
    .dsp_multiply_kind(tdmi_dsp_multiply_kind),
    .timing_kind(tdmi_timing_kind),
    .destination_high_register(tdmi_destination_high_register),
    .accumulator_or_low_register(tdmi_accumulator_or_low_register),
    .multiplier_register(tdmi_multiplier_register),
    .multiplicand_register(tdmi_multiplicand_register),
    .long_result(tdmi_long_result),
    .destination_high_write_enable(tdmi_destination_high_write_enable),
    .destination_high_write_data(tdmi_destination_high_write_data),
    .destination_low_write_enable(tdmi_destination_low_write_enable),
    .destination_low_write_data(tdmi_destination_low_write_data),
    .q_set_request(tdmi_q_set_request),
    .q_out(tdmi_q_out),
    .negative_out(tdmi_negative_out),
    .zero_out(tdmi_zero_out),
    .carry_out(tdmi_carry_out),
    .overflow_out(tdmi_overflow_out),
    .*
  );

  arm9_dsp_multiply_execute #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .decode_match(arm946_decode_match),
    .profile_legal(arm946_profile_legal),
    .profile_illegal_encoding(arm946_profile_illegal_encoding),
    .encoding_valid(arm946_encoding_valid),
    .unpredictable_encoding(arm946_unpredictable_encoding),
    .condition_passed(arm946_condition_passed),
    .unconditional_space(arm946_unconditional_space),
    .execute_valid(arm946_execute_valid),
    .dsp_multiply_kind(arm946_dsp_multiply_kind),
    .timing_kind(arm946_timing_kind),
    .destination_high_register(arm946_destination_high_register),
    .accumulator_or_low_register(arm946_accumulator_or_low_register),
    .multiplier_register(arm946_multiplier_register),
    .multiplicand_register(arm946_multiplicand_register),
    .long_result(arm946_long_result),
    .destination_high_write_enable(arm946_destination_high_write_enable),
    .destination_high_write_data(arm946_destination_high_write_data),
    .destination_low_write_enable(arm946_destination_low_write_enable),
    .destination_low_write_data(arm946_destination_low_write_data),
    .q_set_request(arm946_q_set_request),
    .q_out(arm946_q_out),
    .negative_out(arm946_negative_out),
    .zero_out(arm946_zero_out),
    .carry_out(arm946_carry_out),
    .overflow_out(arm946_overflow_out),
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
    input arm9_dsp_multiply_kind_e kind
  );
    instruction        = 32'he100_0080;
    instruction[19:16] = 4'h1;
    instruction[15:12] = 4'h2;
    instruction[11:8]  = 4'h3;
    instruction[3:0]   = 4'h4;
    case (kind)
      ARM9_DSP_MULTIPLY_SMLA_XY: instruction[23:21] = 3'b000;
      ARM9_DSP_MULTIPLY_SMLAW_Y: instruction[23:21] = 3'b001;
      ARM9_DSP_MULTIPLY_SMULW_Y: begin
        instruction[23:21] = 3'b001;
        instruction[5]     = 1'b1;
        instruction[15:12] = 4'h0;
      end
      ARM9_DSP_MULTIPLY_SMLAL_XY: instruction[23:21] = 3'b010;
      default: begin
        instruction[23:21] = 3'b011;
        instruction[15:12] = 4'h0;
      end
    endcase
  endtask

  initial begin
    logic expected_condition;

    instruction             = '0;
    multiplicand_value      = 32'h1234_fffd;
    multiplier_value        = 32'h8000_0007;
    accumulator_low_value   = 32'h0000_0010;
    accumulator_high_value  = 32'hffff_ffff;
    q_in                    = 1'b0;
    negative_in             = 1'b0;
    zero_in                 = 1'b0;
    carry_in                = 1'b0;
    overflow_in             = 1'b0;
    cases_checked           = 0;

    // REQ: ARM946ES-DSP-MULTIPLY-EXECUTE-001
    // REQ: ARM9TDMI-NO-DSP-MULTIPLY-EXECUTE-001
    for (int unsigned kind = 0; kind < 5; kind++) begin
      for (int unsigned condition = 0; condition < 15; condition++) begin
        for (int unsigned flags = 0; flags < 16; flags++) begin
          encode_kind(arm9_dsp_multiply_kind_e'(kind[2:0]));
          instruction[31:28] = condition[3:0];
          instruction[6:5]   = kind[1:0];
          if (kind == 1) begin
            instruction[5] = 1'b0;
          end else if (kind == 2) begin
            instruction[5] = 1'b1;
          end
          negative_in = flags[3];
          zero_in     = flags[2];
          carry_in    = flags[1];
          overflow_in = flags[0];
          q_in        = kind[0];
          expected_condition = reference_condition(
            condition[3:0], negative_in, zero_in, carry_in, overflow_in
          );
          #1ps;

          assert (tdmi_decode_match && !tdmi_profile_legal);
          assert (tdmi_profile_illegal_encoding && !tdmi_encoding_valid);
          assert (!tdmi_unpredictable_encoding && !tdmi_execute_valid);
          assert (!tdmi_destination_high_write_enable);
          assert (!tdmi_destination_low_write_enable);
          assert (!tdmi_q_set_request && tdmi_q_out == q_in);

          assert (arm946_decode_match && arm946_profile_legal);
          assert (!arm946_profile_illegal_encoding);
          assert (arm946_encoding_valid && !arm946_unpredictable_encoding);
          assert (arm946_condition_passed == expected_condition);
          assert (arm946_execute_valid == expected_condition);
          assert (arm946_destination_high_write_enable ==
                  expected_condition);
          assert (arm946_destination_low_write_enable ==
                  (expected_condition && arm946_long_result));
          assert (!arm946_q_set_request);
          assert (arm946_q_out == q_in);
          assert (arm946_negative_out == negative_in);
          assert (arm946_zero_out == zero_in);
          assert (arm946_carry_out == carry_in);
          assert (arm946_overflow_out == overflow_in);
          assert (tdmi_condition_passed == arm946_condition_passed);
          assert (!tdmi_unconditional_space &&
                  !arm946_unconditional_space);
          assert (arm946_dsp_multiply_kind ==
                  arm9_dsp_multiply_kind_e'(kind[2:0]));
          assert (tdmi_dsp_multiply_kind == arm946_dsp_multiply_kind);
          assert (tdmi_timing_kind == arm946_timing_kind);
          assert (arm946_timing_kind ==
                  ((arm9_dsp_multiply_kind_e'(kind[2:0]) ==
                    ARM9_DSP_MULTIPLY_SMLAL_XY) ?
                   ARM9_MULTIPLY_DSP_LONG : ARM9_MULTIPLY_DSP_SHORT));
          assert (arm946_long_result ==
                  (arm9_dsp_multiply_kind_e'(kind[2:0]) ==
                   ARM9_DSP_MULTIPLY_SMLAL_XY));
          assert (tdmi_destination_high_register == 4'h1);
          assert (arm946_destination_high_register == 4'h1);
          assert (tdmi_accumulator_or_low_register ==
                  arm946_accumulator_or_low_register);
          assert (tdmi_multiplier_register == 4'h3);
          assert (arm946_multiplier_register == 4'h3);
          assert (tdmi_multiplicand_register == 4'h4);
          assert (arm946_multiplicand_register == 4'h4);
          assert (tdmi_long_result == arm946_long_result);
          assert (tdmi_destination_high_write_data ==
                  arm946_destination_high_write_data);
          assert (tdmi_destination_low_write_data ==
                  arm946_destination_low_write_data);
          assert (tdmi_negative_out == negative_in);
          assert (tdmi_zero_out == zero_in);
          assert (tdmi_carry_out == carry_in);
          assert (tdmi_overflow_out == overflow_in);
          cases_checked++;
        end
      end
    end

    encode_kind(ARM9_DSP_MULTIPLY_SMLA_XY);
    multiplicand_value     = 32'h0000_7fff;
    multiplier_value       = 32'h0000_7fff;
    accumulator_low_value  = 32'h7fff_ffff;
    q_in                   = 1'b0;
    #1ps;
    assert (arm946_execute_valid && arm946_q_set_request);
    assert (arm946_q_out);
    assert (arm946_destination_high_write_enable);
    assert (arm946_destination_high_write_data == 32'hbfff_0000);
    assert (!arm946_destination_low_write_enable);
    assert (!tdmi_q_set_request && !tdmi_q_out);
    cases_checked++;

    instruction[31:28] = 4'h0;
    zero_in             = 1'b0;
    #1ps;
    assert (!arm946_condition_passed && !arm946_execute_valid);
    assert (!arm946_q_set_request && !arm946_q_out);
    cases_checked++;

    encode_kind(ARM9_DSP_MULTIPLY_SMLA_XY);
    instruction[19:16] = 4'hf;
    #1ps;
    assert (arm946_unpredictable_encoding && !arm946_encoding_valid);
    assert (!arm946_execute_valid && !arm946_destination_high_write_enable);
    assert (!arm946_q_set_request);
    cases_checked++;

    encode_kind(ARM9_DSP_MULTIPLY_SMUL_XY);
    instruction[31:28] = 4'hf;
    #1ps;
    assert (!arm946_decode_match && !arm946_execute_valid);
    assert (arm946_unconditional_space && tdmi_unconditional_space);
    cases_checked++;

    assert (cases_checked == 1_204);
    $display("PASS profile-separated ARMv5TE DSP multiply execute");
    $finish;
  end
endmodule
