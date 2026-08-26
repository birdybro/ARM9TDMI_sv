module saturating_execute_tb;
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic [31:0] instruction;
  logic [31:0] first_operand_value;
  logic [31:0] second_operand_value;
  logic q_in;
  logic negative_in;
  logic zero_in;
  logic carry_in;
  logic overflow_in;

  logic tdmi_decode_match;
  logic tdmi_profile_legal;
  logic tdmi_profile_illegal_encoding;
  logic tdmi_encoding_valid;
  logic tdmi_unpredictable_encoding;
  logic tdmi_condition_passed;
  logic tdmi_unconditional_space;
  logic tdmi_execute_valid;
  arm9_saturating_kind_e tdmi_saturating_kind;
  logic [3:0] tdmi_destination_register;
  logic [3:0] tdmi_first_operand_register;
  logic [3:0] tdmi_second_operand_register;
  logic tdmi_destination_write_enable;
  logic [31:0] tdmi_destination_write_data;
  logic tdmi_q_set_request;
  logic tdmi_q_out;
  logic tdmi_nzcv_write_enable;
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
  arm9_saturating_kind_e arm946_saturating_kind;
  logic [3:0] arm946_destination_register;
  logic [3:0] arm946_first_operand_register;
  logic [3:0] arm946_second_operand_register;
  logic arm946_destination_write_enable;
  logic [31:0] arm946_destination_write_data;
  logic arm946_q_set_request;
  logic arm946_q_out;
  logic arm946_nzcv_write_enable;
  logic arm946_negative_out;
  logic arm946_zero_out;
  logic arm946_carry_out;
  logic arm946_overflow_out;
  int unsigned cases_checked;

  arm9_saturating_execute #(
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
    .saturating_kind(tdmi_saturating_kind),
    .destination_register(tdmi_destination_register),
    .first_operand_register(tdmi_first_operand_register),
    .second_operand_register(tdmi_second_operand_register),
    .destination_write_enable(tdmi_destination_write_enable),
    .destination_write_data(tdmi_destination_write_data),
    .q_set_request(tdmi_q_set_request),
    .q_out(tdmi_q_out),
    .nzcv_write_enable(tdmi_nzcv_write_enable),
    .negative_out(tdmi_negative_out),
    .zero_out(tdmi_zero_out),
    .carry_out(tdmi_carry_out),
    .overflow_out(tdmi_overflow_out),
    .*
  );

  arm9_saturating_execute #(
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
    .saturating_kind(arm946_saturating_kind),
    .destination_register(arm946_destination_register),
    .first_operand_register(arm946_first_operand_register),
    .second_operand_register(arm946_second_operand_register),
    .destination_write_enable(arm946_destination_write_enable),
    .destination_write_data(arm946_destination_write_data),
    .q_set_request(arm946_q_set_request),
    .q_out(arm946_q_out),
    .nzcv_write_enable(arm946_nzcv_write_enable),
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

  function automatic logic [31:0] ordinary_result(
    input arm9_saturating_kind_e kind
  );
    case (kind)
      ARM9_SATURATING_QADD:  return 32'd8;
      ARM9_SATURATING_QSUB:  return 32'd2;
      ARM9_SATURATING_QDADD: return 32'd11;
      default:               return 32'hffff_ffff;
    endcase
  endfunction

  initial begin
    logic expected_condition;

    instruction          = 32'he102_1053;
    first_operand_value  = 32'd5;
    second_operand_value = 32'd3;
    q_in                 = 1'b0;
    negative_in          = 1'b0;
    zero_in              = 1'b0;
    carry_in             = 1'b0;
    overflow_in          = 1'b0;
    cases_checked        = 0;

    // REQ: ARM946ES-ARM-QADD-EXECUTE-001
    // REQ: ARM9TDMI-NO-ARM-QADD-EXECUTE-001
    for (int unsigned condition = 0; condition < 15; condition++) begin
      for (int unsigned flags = 0; flags < 16; flags++) begin
        for (int unsigned kind = 0; kind < 4; kind++) begin
          for (int unsigned sticky_q = 0; sticky_q < 2; sticky_q++) begin
            instruction = 32'he102_1053;
            instruction[31:28] = condition[3:0];
            instruction[22:21] = kind[1:0];
            first_operand_value  = 32'd5;
            second_operand_value = 32'd3;
            q_in        = sticky_q[0];
            negative_in = flags[3];
            zero_in     = flags[2];
            carry_in    = flags[1];
            overflow_in = flags[0];
            expected_condition = reference_condition(
              condition[3:0], negative_in, zero_in, carry_in, overflow_in
            );
            #1ps;

            assert (tdmi_decode_match && !tdmi_profile_legal);
            assert (tdmi_profile_illegal_encoding);
            assert (!tdmi_encoding_valid && !tdmi_unpredictable_encoding);
            assert (!tdmi_execute_valid && !tdmi_destination_write_enable);
            assert (!tdmi_q_set_request && tdmi_q_out == q_in);
            assert (arm946_decode_match && arm946_profile_legal);
            assert (!arm946_profile_illegal_encoding);
            assert (arm946_encoding_valid &&
                    !arm946_unpredictable_encoding);
            assert (arm946_condition_passed == expected_condition);
            assert (arm946_execute_valid == expected_condition);
            assert (arm946_destination_write_enable == expected_condition);
            assert (arm946_destination_write_data == ordinary_result(
              arm9_saturating_kind_e'(kind[1:0])
            ));
            assert (tdmi_destination_write_data ==
                    arm946_destination_write_data);
            assert (!arm946_q_set_request && arm946_q_out == q_in);
            assert (tdmi_condition_passed == arm946_condition_passed);
            assert (tdmi_saturating_kind ==
                    arm9_saturating_kind_e'(kind[1:0]));
            assert (arm946_saturating_kind ==
                    arm9_saturating_kind_e'(kind[1:0]));
            assert (tdmi_destination_register == 4'h1);
            assert (arm946_destination_register == 4'h1);
            assert (tdmi_first_operand_register == 4'h3);
            assert (arm946_first_operand_register == 4'h3);
            assert (tdmi_second_operand_register == 4'h2);
            assert (arm946_second_operand_register == 4'h2);
            assert (!tdmi_nzcv_write_enable && !arm946_nzcv_write_enable);
            assert (tdmi_negative_out == negative_in &&
                    arm946_negative_out == negative_in);
            assert (tdmi_zero_out == zero_in && arm946_zero_out == zero_in);
            assert (tdmi_carry_out == carry_in &&
                    arm946_carry_out == carry_in);
            assert (tdmi_overflow_out == overflow_in &&
                    arm946_overflow_out == overflow_in);
            assert (!tdmi_unconditional_space &&
                    !arm946_unconditional_space);
            cases_checked++;
          end
        end
      end
    end

    instruction = 32'he102_1053;
    first_operand_value  = 32'h7fff_ffff;
    second_operand_value = 32'd1;
    q_in = 1'b0;
    #1ps;
    assert (arm946_execute_valid && arm946_destination_write_enable);
    assert (arm946_destination_write_data == 32'h7fff_ffff);
    assert (arm946_q_set_request && arm946_q_out);
    assert (!tdmi_q_set_request && !tdmi_q_out);
    cases_checked++;

    instruction[31:28] = 4'h0;
    zero_in = 1'b0;
    #1ps;
    assert (!arm946_condition_passed && !arm946_execute_valid);
    assert (!arm946_destination_write_enable);
    assert (!arm946_q_set_request && !arm946_q_out);
    cases_checked++;

    q_in = 1'b1;
    #1ps;
    assert (!arm946_q_set_request && arm946_q_out);
    cases_checked++;

    instruction = 32'he142_1053;
    first_operand_value  = 32'h8000_0000;
    second_operand_value = 32'h4000_0000;
    q_in = 1'b0;
    #1ps;
    assert (arm946_saturating_kind == ARM9_SATURATING_QDADD);
    assert (arm946_destination_write_data == 32'hffff_ffff);
    assert (arm946_q_set_request && arm946_q_out);
    cases_checked++;

    instruction = 32'he162_1053;
    first_operand_value  = 32'h7fff_ffff;
    second_operand_value = 32'h8000_0000;
    #1ps;
    assert (arm946_saturating_kind == ARM9_SATURATING_QDSUB);
    assert (arm946_destination_write_data == 32'h7fff_ffff);
    assert (arm946_q_set_request && arm946_q_out);
    cases_checked++;

    for (int unsigned operand = 0; operand < 3; operand++) begin
      instruction = 32'he102_1053;
      case (operand)
        0: instruction[15:12] = 4'hf;
        1: instruction[3:0]   = 4'hf;
        default: instruction[19:16] = 4'hf;
      endcase
      #1ps;
      assert (arm946_unpredictable_encoding && !arm946_encoding_valid);
      assert (!arm946_execute_valid && !arm946_destination_write_enable);
      assert (!arm946_q_set_request);
      cases_checked++;
    end

    instruction = 32'hf102_1053;
    #1ps;
    assert (!tdmi_decode_match && !arm946_decode_match);
    assert (tdmi_unconditional_space && arm946_unconditional_space);
    assert (!tdmi_execute_valid && !arm946_execute_valid);
    assert (!tdmi_destination_write_enable &&
            !arm946_destination_write_enable);
    assert (!tdmi_q_set_request && !arm946_q_set_request);
    cases_checked++;

    assert (cases_checked == 1_929);
    $display("PASS integrated profile-specific saturating arithmetic execute");
    $finish;
  end
endmodule
