module saturating_decoder_tb;
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic [31:0] instruction;
  logic tdmi_decode_match;
  logic tdmi_profile_legal;
  logic tdmi_profile_illegal_encoding;
  logic tdmi_encoding_valid;
  logic tdmi_unpredictable_encoding;
  logic [3:0] tdmi_condition;
  arm9_saturating_kind_e tdmi_saturating_kind;
  logic [3:0] tdmi_destination_register;
  logic [3:0] tdmi_first_operand_register;
  logic [3:0] tdmi_second_operand_register;
  logic arm946_decode_match;
  logic arm946_profile_legal;
  logic arm946_profile_illegal_encoding;
  logic arm946_encoding_valid;
  logic arm946_unpredictable_encoding;
  logic [3:0] arm946_condition;
  arm9_saturating_kind_e arm946_saturating_kind;
  logic [3:0] arm946_destination_register;
  logic [3:0] arm946_first_operand_register;
  logic [3:0] arm946_second_operand_register;
  int unsigned cases_checked;

  arm9_saturating_decoder #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .decode_match(tdmi_decode_match),
    .profile_legal(tdmi_profile_legal),
    .profile_illegal_encoding(tdmi_profile_illegal_encoding),
    .encoding_valid(tdmi_encoding_valid),
    .unpredictable_encoding(tdmi_unpredictable_encoding),
    .condition(tdmi_condition),
    .saturating_kind(tdmi_saturating_kind),
    .destination_register(tdmi_destination_register),
    .first_operand_register(tdmi_first_operand_register),
    .second_operand_register(tdmi_second_operand_register),
    .instruction
  );

  arm9_saturating_decoder #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .decode_match(arm946_decode_match),
    .profile_legal(arm946_profile_legal),
    .profile_illegal_encoding(arm946_profile_illegal_encoding),
    .encoding_valid(arm946_encoding_valid),
    .unpredictable_encoding(arm946_unpredictable_encoding),
    .condition(arm946_condition),
    .saturating_kind(arm946_saturating_kind),
    .destination_register(arm946_destination_register),
    .first_operand_register(arm946_first_operand_register),
    .second_operand_register(arm946_second_operand_register),
    .instruction
  );

  function automatic logic is_operation(input logic [7:0] upper_control);
    return (upper_control == 8'h10) || (upper_control == 8'h12) ||
           (upper_control == 8'h14) || (upper_control == 8'h16);
  endfunction

  initial begin
    logic expected_match;
    logic expected_decode;
    logic expected_unpredictable;
    arm9_saturating_kind_e expected_kind;

    instruction   = '0;
    cases_checked = 0;

    // REQ: ARM946ES-ARM-QADD-DECODE-001
    for (int unsigned upper_control = 0; upper_control < 256;
         upper_control++) begin
      for (int unsigned lower_control = 0; lower_control < 256;
           lower_control++) begin
        instruction = 32'he123_4006;
        instruction[27:20] = upper_control[7:0];
        instruction[11:4]  = lower_control[7:0];
        expected_match = is_operation(upper_control[7:0]) &&
                         (lower_control[7:0] == 8'h05);
        #1ps;
        assert (tdmi_decode_match == expected_match);
        assert (!tdmi_profile_legal);
        assert (tdmi_profile_illegal_encoding == expected_match);
        assert (!tdmi_encoding_valid && !tdmi_unpredictable_encoding);
        assert (arm946_decode_match == expected_match);
        assert (arm946_profile_legal == expected_match);
        assert (!arm946_profile_illegal_encoding);
        assert (arm946_encoding_valid == expected_match);
        assert (!arm946_unpredictable_encoding);
        if (expected_match) begin
          expected_kind = arm9_saturating_kind_e'(
            upper_control[2:1]
          );
          assert (tdmi_saturating_kind == expected_kind);
          assert (arm946_saturating_kind == expected_kind);
        end
        cases_checked++;
      end
    end

    // REQ: ARM946ES-ARM-QADD-REGISTERS-001
    // REQ: ARM9TDMI-NO-ARM-QADD-001
    for (int unsigned condition = 0; condition < 16; condition++) begin
      for (int unsigned operation = 0; operation < 4; operation++) begin
        for (int unsigned destination = 0; destination < 16;
             destination++) begin
          for (int unsigned first_operand = 0; first_operand < 16;
               first_operand++) begin
            for (int unsigned second_operand = 0; second_operand < 16;
                 second_operand++) begin
              instruction = 32'he100_0050;
              instruction[31:28] = condition[3:0];
              instruction[22:21] = operation[1:0];
              instruction[19:16] = second_operand[3:0];
              instruction[15:12] = destination[3:0];
              instruction[3:0]   = first_operand[3:0];
              expected_decode = condition != 15;
              expected_unpredictable = expected_decode &&
                ((destination == 15) || (first_operand == 15) ||
                 (second_operand == 15));
              #1ps;

              assert (tdmi_decode_match == expected_decode);
              assert (!tdmi_profile_legal);
              assert (tdmi_profile_illegal_encoding == expected_decode);
              assert (!tdmi_encoding_valid &&
                      !tdmi_unpredictable_encoding);
              assert (arm946_decode_match == expected_decode);
              assert (arm946_profile_legal == expected_decode);
              assert (!arm946_profile_illegal_encoding);
              assert (arm946_unpredictable_encoding ==
                      expected_unpredictable);
              assert (arm946_encoding_valid ==
                      (expected_decode && !expected_unpredictable));
              assert (tdmi_condition == condition[3:0]);
              assert (arm946_condition == condition[3:0]);
              assert (tdmi_saturating_kind ==
                      arm9_saturating_kind_e'(operation[1:0]));
              assert (arm946_saturating_kind ==
                      arm9_saturating_kind_e'(operation[1:0]));
              assert (tdmi_destination_register == destination[3:0]);
              assert (arm946_destination_register == destination[3:0]);
              assert (tdmi_first_operand_register == first_operand[3:0]);
              assert (arm946_first_operand_register == first_operand[3:0]);
              assert (tdmi_second_operand_register == second_operand[3:0]);
              assert (arm946_second_operand_register == second_operand[3:0]);
              cases_checked++;
            end
          end
        end
      end
    end

    assert (cases_checked == 327_680);
    $display("PASS exhaustive profile-specific saturating arithmetic decode (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
