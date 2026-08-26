module doubleword_transfer_prepare_tb;
  import arm9_profile_pkg::*;

  logic [31:0] instruction;
  logic [31:0] base_value;
  logic [31:0] index_value;
  logic [31:0] first_store_register_value;
  logic [31:0] second_store_register_value;
  logic negative;
  logic zero;
  logic carry;
  logic overflow;

  logic tdmi_decode_match;
  logic tdmi_profile_legal;
  logic tdmi_profile_illegal_encoding;
  logic tdmi_undefined_encoding;
  logic tdmi_unpredictable_encoding;
  logic tdmi_unpredictable_access;
  logic tdmi_encoding_valid;
  logic tdmi_condition_passed;
  logic tdmi_unconditional_space;
  logic tdmi_execute_valid;
  logic tdmi_transfer_load;
  logic [3:0] tdmi_base_register;
  logic [3:0] tdmi_first_data_register;
  logic [3:0] tdmi_second_data_register;
  logic [3:0] tdmi_index_register;
  logic tdmi_memory_sequence_valid;
  logic tdmi_memory_write;
  logic [31:0] tdmi_first_word_address;
  logic [31:0] tdmi_second_word_address;
  logic [31:0] tdmi_first_store_value;
  logic [31:0] tdmi_second_store_value;
  logic tdmi_base_writeback_pending;
  logic [31:0] tdmi_base_writeback_value;

  logic arm946_decode_match;
  logic arm946_profile_legal;
  logic arm946_profile_illegal_encoding;
  logic arm946_undefined_encoding;
  logic arm946_unpredictable_encoding;
  logic arm946_unpredictable_access;
  logic arm946_encoding_valid;
  logic arm946_condition_passed;
  logic arm946_unconditional_space;
  logic arm946_execute_valid;
  logic arm946_transfer_load;
  logic [3:0] arm946_base_register;
  logic [3:0] arm946_first_data_register;
  logic [3:0] arm946_second_data_register;
  logic [3:0] arm946_index_register;
  logic arm946_memory_sequence_valid;
  logic arm946_memory_write;
  logic [31:0] arm946_first_word_address;
  logic [31:0] arm946_second_word_address;
  logic [31:0] arm946_first_store_value;
  logic [31:0] arm946_second_store_value;
  logic arm946_base_writeback_pending;
  logic [31:0] arm946_base_writeback_value;
  int unsigned cases_checked;

  arm9_doubleword_transfer_prepare #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .instruction, .base_value, .index_value,
    .first_store_register_value, .second_store_register_value,
    .negative, .zero, .carry, .overflow,
    .decode_match(tdmi_decode_match), .profile_legal(tdmi_profile_legal),
    .profile_illegal_encoding(tdmi_profile_illegal_encoding),
    .undefined_encoding(tdmi_undefined_encoding),
    .unpredictable_encoding(tdmi_unpredictable_encoding),
    .unpredictable_access(tdmi_unpredictable_access),
    .encoding_valid(tdmi_encoding_valid),
    .condition_passed(tdmi_condition_passed),
    .unconditional_space(tdmi_unconditional_space),
    .execute_valid(tdmi_execute_valid), .transfer_load(tdmi_transfer_load),
    .base_register(tdmi_base_register),
    .first_data_register(tdmi_first_data_register),
    .second_data_register(tdmi_second_data_register),
    .index_register(tdmi_index_register),
    .memory_sequence_valid(tdmi_memory_sequence_valid),
    .memory_write(tdmi_memory_write),
    .first_word_address(tdmi_first_word_address),
    .second_word_address(tdmi_second_word_address),
    .first_store_value(tdmi_first_store_value),
    .second_store_value(tdmi_second_store_value),
    .base_writeback_pending(tdmi_base_writeback_pending),
    .base_writeback_value(tdmi_base_writeback_value)
  );

  arm9_doubleword_transfer_prepare #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .instruction, .base_value, .index_value,
    .first_store_register_value, .second_store_register_value,
    .negative, .zero, .carry, .overflow,
    .decode_match(arm946_decode_match),
    .profile_legal(arm946_profile_legal),
    .profile_illegal_encoding(arm946_profile_illegal_encoding),
    .undefined_encoding(arm946_undefined_encoding),
    .unpredictable_encoding(arm946_unpredictable_encoding),
    .unpredictable_access(arm946_unpredictable_access),
    .encoding_valid(arm946_encoding_valid),
    .condition_passed(arm946_condition_passed),
    .unconditional_space(arm946_unconditional_space),
    .execute_valid(arm946_execute_valid),
    .transfer_load(arm946_transfer_load),
    .base_register(arm946_base_register),
    .first_data_register(arm946_first_data_register),
    .second_data_register(arm946_second_data_register),
    .index_register(arm946_index_register),
    .memory_sequence_valid(arm946_memory_sequence_valid),
    .memory_write(arm946_memory_write),
    .first_word_address(arm946_first_word_address),
    .second_word_address(arm946_second_word_address),
    .first_store_value(arm946_first_store_value),
    .second_store_value(arm946_second_store_value),
    .base_writeback_pending(arm946_base_writeback_pending),
    .base_writeback_value(arm946_base_writeback_value)
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

  initial begin
    logic expected_condition;
    logic expected_encoding;
    logic expected_writeback;
    logic [31:0] expected_adjusted;

    instruction = 32'he1c1_20d8;
    base_value = 32'h1000_0000;
    index_value = 32'h0000_0008;
    first_store_register_value = 32'h0123_4567;
    second_store_register_value = 32'h89ab_cdef;
    negative = 1'b0;
    zero = 1'b0;
    carry = 1'b0;
    overflow = 1'b0;
    cases_checked = 0;

    // REQ: ARM946ES-ARM-DOUBLEWORD-PREPARE-001
    for (int unsigned store_case = 0; store_case < 2; store_case++) begin
      for (int unsigned immediate_case = 0; immediate_case < 2;
           immediate_case++) begin
        for (int unsigned controls = 0; controls < 8; controls++) begin
          for (int unsigned condition_case = 0; condition_case < 15;
               condition_case++) begin
            for (int unsigned flags = 0; flags < 16; flags++) begin
              instruction = store_case[0] ? 32'he1c1_20f8 :
                                            32'he1c1_20d8;
              instruction[31:28] = condition_case[3:0];
              instruction[24:23] = controls[2:1];
              instruction[22] = immediate_case[0];
              instruction[21] = controls[0];
              instruction[11:8] = 4'h0;
              instruction[3:0] = 4'h8;
              negative = flags[3];
              zero = flags[2];
              carry = flags[1];
              overflow = flags[0];
              expected_condition = reference_condition(
                condition_case[3:0], negative, zero, carry, overflow
              );
              expected_encoding = instruction[24] || !instruction[21];
              expected_writeback = !instruction[24] || instruction[21];
              expected_adjusted = instruction[23] ?
                (base_value + 32'd8) : (base_value - 32'd8);
              #1ps;

              assert (arm946_decode_match && arm946_profile_legal);
              assert (!arm946_profile_illegal_encoding &&
                      !arm946_undefined_encoding);
              assert (arm946_encoding_valid == expected_encoding);
              assert (arm946_unpredictable_encoding == !expected_encoding);
              assert (!arm946_unpredictable_access);
              assert (arm946_condition_passed == expected_condition);
              assert (arm946_execute_valid ==
                      (expected_encoding && expected_condition));
              assert (arm946_memory_sequence_valid ==
                      arm946_execute_valid);
              assert (arm946_memory_write ==
                      (arm946_execute_valid && store_case[0]));
              assert (arm946_transfer_load == !store_case[0]);
              assert (arm946_first_word_address ==
                      (instruction[24] ? expected_adjusted : base_value));
              assert (arm946_second_word_address ==
                      arm946_first_word_address + 32'd4);
              assert (arm946_base_writeback_pending ==
                      (arm946_execute_valid && expected_writeback));
              assert (arm946_base_writeback_value == expected_adjusted);
              assert (arm946_base_register == 4'h1);
              assert (arm946_first_data_register == 4'h2);
              assert (arm946_second_data_register == 4'h3);
              assert (arm946_index_register == 4'h8);
              assert (arm946_first_store_value ==
                      first_store_register_value);
              assert (arm946_second_store_value ==
                      second_store_register_value);
              assert (!arm946_unconditional_space);

              assert (tdmi_decode_match && !tdmi_profile_legal);
              assert (tdmi_profile_illegal_encoding);
              assert (!tdmi_undefined_encoding &&
                      !tdmi_unpredictable_encoding &&
                      !tdmi_unpredictable_access && !tdmi_encoding_valid);
              assert (tdmi_condition_passed == expected_condition);
              assert (!tdmi_execute_valid && !tdmi_memory_sequence_valid &&
                      !tdmi_memory_write && !tdmi_base_writeback_pending);
              assert (tdmi_transfer_load == arm946_transfer_load);
              assert (tdmi_base_register == arm946_base_register);
              assert (tdmi_first_data_register ==
                      arm946_first_data_register);
              assert (tdmi_second_data_register ==
                      arm946_second_data_register);
              assert (tdmi_index_register == arm946_index_register);
              assert (tdmi_first_word_address == arm946_first_word_address);
              assert (tdmi_second_word_address == arm946_second_word_address);
              assert (tdmi_first_store_value == arm946_first_store_value);
              assert (tdmi_second_store_value == arm946_second_store_value);
              assert (tdmi_base_writeback_value ==
                      arm946_base_writeback_value);
              assert (!tdmi_unconditional_space);
              cases_checked++;
            end
          end
        end
      end
    end

    // REQ: ARM946ES-ARM-DOUBLEWORD-ALIGNMENT-GATE-001
    for (int unsigned pass_case = 0; pass_case < 2; pass_case++) begin
      for (int unsigned low_case = 0; low_case < 8; low_case++) begin
        instruction = 32'he1c1_20d0;
        instruction[31:28] = 4'h0;
        base_value = 32'h2000_0000 | low_case;
        zero = pass_case[0];
        #1ps;
        assert (arm946_condition_passed == pass_case[0]);
        assert (arm946_unpredictable_access ==
                (pass_case[0] && (low_case != 0)));
        assert (arm946_execute_valid ==
                (pass_case[0] && (low_case == 0)));
        cases_checked++;
      end
    end

    instruction = 32'he1c1_10d0;
    base_value = 32'h2000_0000;
    zero = 1'b1;
    #1ps;
    assert (arm946_undefined_encoding && !arm946_encoding_valid);
    assert (!arm946_execute_valid && !arm946_memory_sequence_valid);
    cases_checked++;

    assert (cases_checked == 7_697);
    $display("PASS condition-gated profile doubleword preparation (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
