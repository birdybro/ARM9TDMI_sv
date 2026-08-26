module clz_execute_tb;
  import arm9_profile_pkg::*;

  logic [31:0] instruction;
  logic [31:0] source_value;
  logic negative;
  logic zero;
  logic carry;
  logic overflow;

  logic tdmi_decode_match;
  logic tdmi_profile_legal;
  logic tdmi_profile_illegal_encoding;
  logic tdmi_encoding_valid;
  logic tdmi_unpredictable_encoding;
  logic tdmi_condition_passed;
  logic tdmi_unconditional_space;
  logic tdmi_execute_valid;
  logic [3:0] tdmi_destination_register;
  logic [3:0] tdmi_source_register;
  logic tdmi_destination_write_enable;
  logic [31:0] tdmi_destination_write_data;
  logic tdmi_flags_write_enable;

  logic arm946_decode_match;
  logic arm946_profile_legal;
  logic arm946_profile_illegal_encoding;
  logic arm946_encoding_valid;
  logic arm946_unpredictable_encoding;
  logic arm946_condition_passed;
  logic arm946_unconditional_space;
  logic arm946_execute_valid;
  logic [3:0] arm946_destination_register;
  logic [3:0] arm946_source_register;
  logic arm946_destination_write_enable;
  logic [31:0] arm946_destination_write_data;
  logic arm946_flags_write_enable;
  int unsigned cases_checked;

  arm9_clz_execute #(
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
    .destination_register(tdmi_destination_register),
    .source_register(tdmi_source_register),
    .destination_write_enable(tdmi_destination_write_enable),
    .destination_write_data(tdmi_destination_write_data),
    .flags_write_enable(tdmi_flags_write_enable),
    .*
  );

  arm9_clz_execute #(
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
    .destination_register(arm946_destination_register),
    .source_register(arm946_source_register),
    .destination_write_enable(arm946_destination_write_enable),
    .destination_write_data(arm946_destination_write_data),
    .flags_write_enable(arm946_flags_write_enable),
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

  function automatic logic [31:0] reference_clz(input logic [31:0] value);
    logic found;
    begin
      reference_clz = 32'd32;
      found = 1'b0;
      for (int unsigned bit_number = 0; bit_number < 32; bit_number++) begin
        if (!found && value[31-bit_number]) begin
          reference_clz = bit_number;
          found = 1'b1;
        end
      end
    end
  endfunction

  initial begin
    logic expected_match;
    logic expected_condition;
    logic expected_valid;

    instruction   = 32'he16f_1f13;
    source_value  = 32'h0001_ffff;
    negative      = 1'b0;
    zero          = 1'b0;
    carry         = 1'b0;
    overflow      = 1'b0;
    cases_checked = 0;

    // REQ: ARM946ES-ARM-CLZ-ENCODING-001
    // Exhaust the fixed upper and lower control fields independently of Rd/Rm.
    for (int unsigned upper_control = 0; upper_control < 256;
         upper_control++) begin
      for (int unsigned lower_control = 0; lower_control < 256;
           lower_control++) begin
        instruction = 32'he000_0000;
        instruction[27:20] = upper_control[7:0];
        instruction[19:16] = 4'hf;
        instruction[15:12] = 4'h2;
        instruction[11:4]  = lower_control[7:0];
        instruction[3:0]   = 4'h3;
        expected_match = (upper_control[7:0] == 8'h16) &&
                         (lower_control[7:0] == 8'hf1);
        #1ps;
        assert (tdmi_decode_match == expected_match);
        assert (arm946_decode_match == expected_match);
        assert (tdmi_profile_legal == 1'b0);
        assert (tdmi_profile_illegal_encoding == expected_match);
        assert (!tdmi_encoding_valid && !tdmi_unpredictable_encoding);
        assert (!tdmi_execute_valid && !tdmi_destination_write_enable);
        assert (arm946_profile_legal == expected_match);
        assert (!arm946_profile_illegal_encoding);
        assert (arm946_encoding_valid == expected_match);
        assert (!arm946_unpredictable_encoding);
        assert (arm946_execute_valid == expected_match);
        assert (arm946_destination_write_enable == expected_match);
        assert (!tdmi_flags_write_enable && !arm946_flags_write_enable);
        cases_checked++;
      end
    end

    // REQ: ARM946ES-ARM-CLZ-EXECUTE-001
    // REQ: ARM9TDMI-NO-ARM-CLZ-001
    for (int unsigned condition = 0; condition < 15; condition++) begin
      for (int unsigned flags = 0; flags < 16; flags++) begin
        for (int unsigned destination = 0; destination < 16;
             destination++) begin
          for (int unsigned source = 0; source < 16; source++) begin
            instruction = 32'he16f_0f10;
            instruction[31:28] = condition[3:0];
            instruction[15:12] = destination[3:0];
            instruction[3:0]   = source[3:0];
            negative = flags[3];
            zero     = flags[2];
            carry    = flags[1];
            overflow = flags[0];
            source_value = 32'h0001_ffff;
            expected_condition = reference_condition(
              condition[3:0], negative, zero, carry, overflow
            );
            expected_valid = (destination != 15) && (source != 15);
            #1ps;

            assert (tdmi_decode_match && !tdmi_profile_legal);
            assert (tdmi_profile_illegal_encoding);
            assert (!tdmi_encoding_valid && !tdmi_unpredictable_encoding);
            assert (!tdmi_execute_valid && !tdmi_destination_write_enable);
            assert (tdmi_condition_passed == expected_condition);
            assert (tdmi_destination_write_data == 32'd15);
            assert (arm946_decode_match && arm946_profile_legal);
            assert (!arm946_profile_illegal_encoding);
            assert (arm946_unpredictable_encoding == !expected_valid);
            assert (arm946_encoding_valid == expected_valid);
            assert (arm946_condition_passed == expected_condition);
            assert (arm946_execute_valid ==
                    (expected_valid && expected_condition));
            assert (arm946_destination_write_enable ==
                    arm946_execute_valid);
            assert (arm946_destination_write_data == 32'd15);
            assert (tdmi_destination_register == destination[3:0]);
            assert (arm946_destination_register == destination[3:0]);
            assert (tdmi_source_register == source[3:0]);
            assert (arm946_source_register == source[3:0]);
            assert (!tdmi_flags_write_enable && !arm946_flags_write_enable);
            cases_checked++;
          end
        end
      end
    end

    instruction = 32'he16f_1f12;
    for (int unsigned leading_zeros = 0; leading_zeros < 32;
         leading_zeros++) begin
      source_value = 32'hffff_ffff >> leading_zeros;
      #1ps;
      assert (arm946_execute_valid);
      assert (arm946_destination_write_data == leading_zeros);
      cases_checked++;
    end
    source_value = 32'b0;
    #1ps;
    assert (arm946_destination_write_data == 32'd32);
    cases_checked++;

    instruction[31:28] = 4'hf;
    #1ps;
    assert (!tdmi_decode_match && !arm946_decode_match);
    assert (tdmi_unconditional_space && arm946_unconditional_space);
    assert (!tdmi_destination_write_enable &&
            !arm946_destination_write_enable);
    cases_checked++;

    assert (reference_clz(32'h8000_0000) == 32'd0);
    assert (reference_clz(32'h0000_0001) == 32'd31);
    assert (reference_clz(32'b0) == 32'd32);
    assert (cases_checked == 127_010);
    $display("PASS exhaustive profile-specific ARM CLZ execute (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
