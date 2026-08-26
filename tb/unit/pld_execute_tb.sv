module pld_execute_tb;
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;

  logic [31:0] instruction;
  logic [31:0] base_value;
  logic [31:0] index_value;
  logic carry_in;

  logic tdmi_decode_match;
  logic tdmi_profile_legal;
  logic tdmi_profile_illegal_encoding;
  logic tdmi_encoding_valid;
  logic tdmi_unpredictable_encoding;
  logic tdmi_unconditional_space;
  logic tdmi_execute_valid;
  logic tdmi_immediate_offset;
  logic tdmi_add_offset;
  logic [3:0] tdmi_base_register;
  logic [3:0] tdmi_index_register;
  logic [4:0] tdmi_shift_amount;
  arm9_shift_type_e tdmi_shift_type;
  logic [31:0] tdmi_offset_value;
  logic tdmi_shift_carry_out;
  logic [31:0] tdmi_prefetch_address;
  logic tdmi_prefetch_address_valid;
  logic tdmi_data_speculative;
  logic tdmi_architectural_state_write_enable;
  logic tdmi_precise_data_abort_possible;

  logic arm946_decode_match;
  logic arm946_profile_legal;
  logic arm946_profile_illegal_encoding;
  logic arm946_encoding_valid;
  logic arm946_unpredictable_encoding;
  logic arm946_unconditional_space;
  logic arm946_execute_valid;
  logic arm946_immediate_offset;
  logic arm946_add_offset;
  logic [3:0] arm946_base_register;
  logic [3:0] arm946_index_register;
  logic [4:0] arm946_shift_amount;
  arm9_shift_type_e arm946_shift_type;
  logic [31:0] arm946_offset_value;
  logic arm946_shift_carry_out;
  logic [31:0] arm946_prefetch_address;
  logic arm946_prefetch_address_valid;
  logic arm946_data_speculative;
  logic arm946_architectural_state_write_enable;
  logic arm946_precise_data_abort_possible;
  int unsigned cases_checked;

  arm9_pld_execute #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .decode_match(tdmi_decode_match),
    .profile_legal(tdmi_profile_legal),
    .profile_illegal_encoding(tdmi_profile_illegal_encoding),
    .encoding_valid(tdmi_encoding_valid),
    .unpredictable_encoding(tdmi_unpredictable_encoding),
    .unconditional_space(tdmi_unconditional_space),
    .execute_valid(tdmi_execute_valid),
    .immediate_offset(tdmi_immediate_offset),
    .add_offset(tdmi_add_offset),
    .base_register(tdmi_base_register),
    .index_register(tdmi_index_register),
    .shift_amount(tdmi_shift_amount),
    .shift_type(tdmi_shift_type),
    .offset_value(tdmi_offset_value),
    .shift_carry_out(tdmi_shift_carry_out),
    .prefetch_address(tdmi_prefetch_address),
    .prefetch_address_valid(tdmi_prefetch_address_valid),
    .data_speculative(tdmi_data_speculative),
    .architectural_state_write_enable(
      tdmi_architectural_state_write_enable
    ),
    .precise_data_abort_possible(tdmi_precise_data_abort_possible),
    .*
  );

  arm9_pld_execute #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .decode_match(arm946_decode_match),
    .profile_legal(arm946_profile_legal),
    .profile_illegal_encoding(arm946_profile_illegal_encoding),
    .encoding_valid(arm946_encoding_valid),
    .unpredictable_encoding(arm946_unpredictable_encoding),
    .unconditional_space(arm946_unconditional_space),
    .execute_valid(arm946_execute_valid),
    .immediate_offset(arm946_immediate_offset),
    .add_offset(arm946_add_offset),
    .base_register(arm946_base_register),
    .index_register(arm946_index_register),
    .shift_amount(arm946_shift_amount),
    .shift_type(arm946_shift_type),
    .offset_value(arm946_offset_value),
    .shift_carry_out(arm946_shift_carry_out),
    .prefetch_address(arm946_prefetch_address),
    .prefetch_address_valid(arm946_prefetch_address_valid),
    .data_speculative(arm946_data_speculative),
    .architectural_state_write_enable(
      arm946_architectural_state_write_enable
    ),
    .precise_data_abort_possible(arm946_precise_data_abort_possible),
    .*
  );

  function automatic logic [32:0] reference_shift(
    input logic [31:0] value,
    input arm9_shift_type_e kind,
    input logic [4:0] amount,
    input logic carry
  );
    logic [31:0] shifted;
    logic shifted_carry;
    int unsigned count;
    begin
      count = {27'b0, amount};
      shifted = value;
      shifted_carry = carry;
      case (kind)
        ARM9_SHIFT_LSL: begin
          if (count != 0) begin
            shifted = value << count;
            shifted_carry = value[32-count];
          end
        end
        ARM9_SHIFT_LSR: begin
          if (count == 0) begin
            shifted = 32'b0;
            shifted_carry = value[31];
          end else begin
            shifted = value >> count;
            shifted_carry = value[count-1];
          end
        end
        ARM9_SHIFT_ASR: begin
          if (count == 0) begin
            shifted = {32{value[31]}};
            shifted_carry = value[31];
          end else begin
            shifted = $unsigned($signed(value) >>> count);
            shifted_carry = value[count-1];
          end
        end
        default: begin
          if (count == 0) begin
            shifted = {carry, value[31:1]};
            shifted_carry = value[0];
          end else begin
            shifted = (value >> count) | (value << (32-count));
            shifted_carry = value[count-1];
          end
        end
      endcase
      return {shifted_carry, shifted};
    end
  endfunction

  function automatic logic [31:0] test_value(input int unsigned index);
    case (index)
      0: return 32'h0000_0000;
      1: return 32'h0000_0001;
      2: return 32'h8000_0000;
      3: return 32'hffff_ffff;
      default: return 32'h1234_5678;
    endcase
  endfunction

  task automatic check_no_architectural_side_effects;
    assert (!tdmi_architectural_state_write_enable);
    assert (!tdmi_precise_data_abort_possible);
    assert (!arm946_architectural_state_write_enable);
    assert (!arm946_precise_data_abort_possible);
  endtask

  initial begin
    logic expected_match;
    logic expected_unpredictable;
    logic [32:0] expected_shift;
    logic [31:0] expected_offset;
    logic [31:0] expected_address;

    instruction = 32'hf5d1_f004;
    base_value = 32'h1000_0000;
    index_value = 32'h0000_0004;
    carry_in = 1'b0;
    cases_checked = 0;

    // REQ: ARM946ES-ARM-PLD-ENCODING-001
    // REQ: ARM946ES-ARM-PLD-CONSTRAINTS-001
    // REQ: ARM9TDMI-NO-ARM-PLD-001
    for (int unsigned condition = 0; condition < 16; condition++) begin
      for (int unsigned upper_control = 0; upper_control < 256;
           upper_control++) begin
        for (int unsigned destination = 0; destination < 16;
             destination++) begin
          for (int unsigned bit_four = 0; bit_four < 2; bit_four++) begin
            instruction = 32'h0000_0003;
            instruction[31:28] = condition[3:0];
            instruction[27:20] = upper_control[7:0];
            instruction[15:12] = destination[3:0];
            instruction[4] = bit_four[0];
            expected_match =
              (condition == 15) &&
              (upper_control[7:6] == 2'b01) &&
              upper_control[2] && upper_control[0] &&
              (destination == 15) &&
              (!upper_control[5] || !bit_four[0]);
            expected_unpredictable = expected_match &&
              (!upper_control[4] || upper_control[1]);
            #1ps;
            assert (tdmi_decode_match == expected_match);
            assert (!tdmi_profile_legal);
            assert (tdmi_profile_illegal_encoding == expected_match);
            assert (!tdmi_encoding_valid &&
                    !tdmi_unpredictable_encoding &&
                    !tdmi_execute_valid);
            assert (arm946_decode_match == expected_match);
            assert (arm946_profile_legal == expected_match);
            assert (!arm946_profile_illegal_encoding);
            assert (arm946_unpredictable_encoding ==
                    expected_unpredictable);
            assert (arm946_encoding_valid ==
                    (expected_match && !expected_unpredictable));
            assert (arm946_execute_valid == arm946_encoding_valid);
            assert (tdmi_unconditional_space == (condition == 15));
            assert (arm946_unconditional_space == (condition == 15));
            assert (tdmi_prefetch_address_valid == 1'b0);
            assert (tdmi_data_speculative == 1'b0);
            assert (arm946_prefetch_address_valid ==
                    arm946_execute_valid);
            assert (arm946_data_speculative == arm946_execute_valid);
            check_no_architectural_side_effects();
            cases_checked++;
          end
        end
      end
    end

    // REQ: ARM946ES-ARM-PLD-EXECUTE-001
    for (int unsigned add = 0; add < 2; add++) begin
      for (int unsigned immediate = 0; immediate < 3; immediate++) begin
        for (int unsigned base_index = 0; base_index < 5;
             base_index++) begin
          instruction = 32'hf5d1_f000;
          instruction[23] = add[0];
          instruction[11:0] = (immediate == 0) ? 12'h000 :
                               (immediate == 1) ? 12'h001 : 12'hfff;
          base_value = test_value(base_index);
          expected_offset = {20'b0, instruction[11:0]};
          expected_address = add[0] ? base_value + expected_offset :
                                      base_value - expected_offset;
          #1ps;
          assert (arm946_decode_match && arm946_encoding_valid);
          assert (arm946_execute_valid && arm946_immediate_offset);
          assert (arm946_add_offset == add[0]);
          assert (arm946_offset_value == expected_offset);
          assert (arm946_prefetch_address == expected_address);
          assert (arm946_base_register == 4'h1);
          assert (tdmi_immediate_offset == arm946_immediate_offset);
          assert (tdmi_add_offset == arm946_add_offset);
          assert (tdmi_base_register == arm946_base_register);
          assert (tdmi_offset_value == arm946_offset_value);
          assert (tdmi_prefetch_address == arm946_prefetch_address);
          check_no_architectural_side_effects();
          cases_checked++;
        end
      end
    end

    for (int unsigned add = 0; add < 2; add++) begin
      for (int unsigned kind = 0; kind < 4; kind++) begin
        for (int unsigned amount = 0; amount < 32; amount++) begin
          for (int unsigned value_index = 0; value_index < 5;
               value_index++) begin
            for (int unsigned carry = 0; carry < 2; carry++) begin
              instruction = 32'hf7d1_f003;
              instruction[23] = add[0];
              instruction[11:7] = amount[4:0];
              instruction[6:5] = kind[1:0];
              index_value = test_value(value_index);
              carry_in = carry[0];
              expected_shift = reference_shift(
                index_value, arm9_shift_type_e'(kind[1:0]),
                amount[4:0], carry_in
              );
              expected_address = add[0] ?
                base_value + expected_shift[31:0] :
                base_value - expected_shift[31:0];
              #1ps;
              assert (arm946_decode_match && arm946_encoding_valid);
              assert (!arm946_immediate_offset && arm946_execute_valid);
              assert (arm946_index_register == 4'h3);
              assert (arm946_shift_amount == amount[4:0]);
              assert (arm946_shift_type ==
                      arm9_shift_type_e'(kind[1:0]));
              assert (arm946_offset_value == expected_shift[31:0]);
              assert (arm946_shift_carry_out == expected_shift[32]);
              assert (arm946_prefetch_address == expected_address);
              assert (tdmi_index_register == arm946_index_register);
              assert (tdmi_shift_amount == arm946_shift_amount);
              assert (tdmi_shift_type == arm946_shift_type);
              assert (tdmi_shift_carry_out == arm946_shift_carry_out);
              check_no_architectural_side_effects();
              cases_checked++;
            end
          end
        end
      end
    end

    instruction = 32'hf7d1_f00f;
    #1ps;
    assert (arm946_decode_match && arm946_profile_legal);
    assert (arm946_unpredictable_encoding && !arm946_encoding_valid);
    assert (!arm946_execute_valid && !arm946_data_speculative);
    cases_checked++;

    assert (cases_checked == 133_663);
    $display("PASS exhaustive profile-specific ARM PLD execution (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
