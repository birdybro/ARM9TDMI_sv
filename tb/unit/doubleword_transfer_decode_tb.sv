module doubleword_transfer_decode_tb;
  import arm9_profile_pkg::*;

  logic [31:0] instruction;
  logic [31:0] base_value;
  logic [31:0] index_value;

  logic tdmi_decode_match;
  logic tdmi_profile_legal;
  logic tdmi_profile_illegal_encoding;
  logic tdmi_undefined_encoding;
  logic tdmi_unpredictable_encoding;
  logic tdmi_encoding_valid;
  logic tdmi_unaligned_access_unpredictable;
  logic [3:0] tdmi_condition;
  logic tdmi_transfer_load;
  logic tdmi_immediate_offset;
  logic tdmi_pre_index;
  logic tdmi_add_offset;
  logic tdmi_writeback;
  logic [3:0] tdmi_base_register;
  logic [3:0] tdmi_first_data_register;
  logic [3:0] tdmi_second_data_register;
  logic [3:0] tdmi_index_register;
  logic [31:0] tdmi_offset_value;
  logic [31:0] tdmi_effective_address;
  logic [31:0] tdmi_second_word_address;
  logic [31:0] tdmi_writeback_address;

  logic arm946_decode_match;
  logic arm946_profile_legal;
  logic arm946_profile_illegal_encoding;
  logic arm946_undefined_encoding;
  logic arm946_unpredictable_encoding;
  logic arm946_encoding_valid;
  logic arm946_unaligned_access_unpredictable;
  logic [3:0] arm946_condition;
  logic arm946_transfer_load;
  logic arm946_immediate_offset;
  logic arm946_pre_index;
  logic arm946_add_offset;
  logic arm946_writeback;
  logic [3:0] arm946_base_register;
  logic [3:0] arm946_first_data_register;
  logic [3:0] arm946_second_data_register;
  logic [3:0] arm946_index_register;
  logic [31:0] arm946_offset_value;
  logic [31:0] arm946_effective_address;
  logic [31:0] arm946_second_word_address;
  logic [31:0] arm946_writeback_address;
  int unsigned cases_checked;

  arm9_doubleword_transfer_decode #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .instruction, .base_value, .index_value,
    .decode_match(tdmi_decode_match),
    .profile_legal(tdmi_profile_legal),
    .profile_illegal_encoding(tdmi_profile_illegal_encoding),
    .undefined_encoding(tdmi_undefined_encoding),
    .unpredictable_encoding(tdmi_unpredictable_encoding),
    .encoding_valid(tdmi_encoding_valid),
    .unaligned_access_unpredictable(tdmi_unaligned_access_unpredictable),
    .condition(tdmi_condition), .transfer_load(tdmi_transfer_load),
    .immediate_offset(tdmi_immediate_offset), .pre_index(tdmi_pre_index),
    .add_offset(tdmi_add_offset), .writeback(tdmi_writeback),
    .base_register(tdmi_base_register),
    .first_data_register(tdmi_first_data_register),
    .second_data_register(tdmi_second_data_register),
    .index_register(tdmi_index_register), .offset_value(tdmi_offset_value),
    .effective_address(tdmi_effective_address),
    .second_word_address(tdmi_second_word_address),
    .writeback_address(tdmi_writeback_address)
  );

  arm9_doubleword_transfer_decode #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .instruction, .base_value, .index_value,
    .decode_match(arm946_decode_match),
    .profile_legal(arm946_profile_legal),
    .profile_illegal_encoding(arm946_profile_illegal_encoding),
    .undefined_encoding(arm946_undefined_encoding),
    .unpredictable_encoding(arm946_unpredictable_encoding),
    .encoding_valid(arm946_encoding_valid),
    .unaligned_access_unpredictable(arm946_unaligned_access_unpredictable),
    .condition(arm946_condition), .transfer_load(arm946_transfer_load),
    .immediate_offset(arm946_immediate_offset),
    .pre_index(arm946_pre_index), .add_offset(arm946_add_offset),
    .writeback(arm946_writeback), .base_register(arm946_base_register),
    .first_data_register(arm946_first_data_register),
    .second_data_register(arm946_second_data_register),
    .index_register(arm946_index_register),
    .offset_value(arm946_offset_value),
    .effective_address(arm946_effective_address),
    .second_word_address(arm946_second_word_address),
    .writeback_address(arm946_writeback_address)
  );

  initial begin
    logic expected_decode;
    logic expected_writeback;
    logic expected_undefined;
    logic expected_unpredictable;
    logic [31:0] expected_offset;
    logic [31:0] expected_adjusted;

    instruction = 32'he1c1_20d4;
    base_value = 32'h1000_0000;
    index_value = 32'h0000_0008;
    cases_checked = 0;

    // REQ: ARM946ES-ARM-DOUBLEWORD-DECODE-001
    // REQ: ARM9TDMI-ARM-DOUBLEWORD-EXCLUDE-001
    for (int unsigned condition_case = 0; condition_case < 16;
         condition_case++) begin
      for (int unsigned upper_control = 0; upper_control < 256;
           upper_control++) begin
        for (int unsigned low_control = 0; low_control < 16;
             low_control++) begin
          instruction = '0;
          instruction[31:28] = condition_case[3:0];
          instruction[27:20] = upper_control[7:0];
          instruction[19:16] = 4'h1;
          instruction[15:12] = 4'h2;
          instruction[7:4] = low_control[3:0];
          instruction[3:0] = 4'h4;
          expected_decode = (condition_case != 15) &&
            (upper_control[7:5] == 3'b000) && !upper_control[0] &&
            low_control[3] && low_control[2] && low_control[0];
          #1ps;
          assert (tdmi_decode_match == expected_decode);
          assert (arm946_decode_match == expected_decode);
          assert (!tdmi_profile_legal);
          assert (tdmi_profile_illegal_encoding == expected_decode);
          assert (!tdmi_undefined_encoding &&
                  !tdmi_unpredictable_encoding && !tdmi_encoding_valid);
          assert (!tdmi_unaligned_access_unpredictable);
          assert (arm946_profile_legal == expected_decode);
          assert (!arm946_profile_illegal_encoding);
          assert (tdmi_condition == condition_case[3:0]);
          assert (arm946_condition == condition_case[3:0]);
          assert (tdmi_transfer_load == arm946_transfer_load);
          assert (tdmi_immediate_offset == arm946_immediate_offset);
          assert (tdmi_pre_index == arm946_pre_index);
          assert (tdmi_add_offset == arm946_add_offset);
          assert (tdmi_writeback == arm946_writeback);
          assert (tdmi_base_register == arm946_base_register);
          assert (tdmi_first_data_register == arm946_first_data_register);
          assert (tdmi_second_data_register == arm946_second_data_register);
          assert (tdmi_index_register == arm946_index_register);
          assert (tdmi_offset_value == arm946_offset_value);
          assert (tdmi_effective_address == arm946_effective_address);
          assert (tdmi_second_word_address == arm946_second_word_address);
          assert (tdmi_writeback_address == arm946_writeback_address);
          cases_checked++;
        end
      end
    end

    // REQ: ARM946ES-ARM-DOUBLEWORD-ADDRESS-001
    for (int unsigned controls = 0; controls < 16; controls++) begin
      for (int unsigned offset_case = 0; offset_case < 3;
           offset_case++) begin
        for (int unsigned base_case = 0; base_case < 4; base_case++) begin
          instruction = 32'he1c1_20d0;
          instruction[24:21] = controls[3:0];
          instruction[11:8] = (offset_case == 0) ? 4'h0 :
                              (offset_case == 1) ? 4'h0 : 4'hf;
          instruction[3:0] = (offset_case == 0) ? 4'h0 :
                             (offset_case == 1) ? 4'h8 : 4'hf;
          base_value = (base_case == 0) ? 32'h0000_0000 :
                       (base_case == 1) ? 32'h0000_0008 :
                       (base_case == 2) ? 32'hffff_fff8 :
                                          32'h1234_5670;
          index_value = (offset_case == 0) ? 32'h0000_0000 :
                        (offset_case == 1) ? 32'h0000_0008 :
                                             32'hffff_fff8;
          expected_offset = instruction[22] ?
            {24'b0, instruction[11:8], instruction[3:0]} : index_value;
          expected_adjusted = instruction[23] ?
            (base_value + expected_offset) : (base_value - expected_offset);
          #1ps;
          assert (arm946_decode_match && arm946_profile_legal);
          assert (arm946_immediate_offset == instruction[22]);
          assert (arm946_pre_index == instruction[24]);
          assert (arm946_add_offset == instruction[23]);
          assert (arm946_offset_value == expected_offset);
          assert (arm946_writeback_address == expected_adjusted);
          assert (arm946_effective_address ==
                  (instruction[24] ? expected_adjusted : base_value));
          assert (arm946_second_word_address ==
                  arm946_effective_address + 32'd4);
          cases_checked++;
        end
      end
    end

    // REQ: ARM946ES-ARM-DOUBLEWORD-CONSTRAINTS-001
    for (int unsigned store_case = 0; store_case < 2; store_case++) begin
      for (int unsigned controls = 0; controls < 16; controls++) begin
        for (int unsigned reserved_case = 0; reserved_case < 2;
             reserved_case++) begin
          for (int unsigned rn = 0; rn < 16; rn++) begin
            for (int unsigned rd = 0; rd < 16; rd++) begin
              for (int unsigned rm = 0; rm < 16; rm++) begin
                instruction = store_case[0] ? 32'he181_20f3 :
                                              32'he181_20d3;
                instruction[24:21] = controls[3:0];
                instruction[19:16] = rn[3:0];
                instruction[15:12] = rd[3:0];
                instruction[11:8] = reserved_case[0] ? 4'ha : 4'h0;
                instruction[3:0] = rm[3:0];
                expected_writeback = !instruction[24] || instruction[21];
                expected_undefined = rd[0];
                expected_unpredictable = !expected_undefined &&
                  ((!instruction[22] && reserved_case[0]) ||
                   (!instruction[24] && instruction[21]) ||
                   (expected_writeback && (rn == 15)) ||
                   (expected_writeback &&
                    ((rn == rd) || (rn == ((rd + 1) & 15)))) ||
                   (!instruction[22] && expected_writeback && (rn == rm)) ||
                   (!instruction[22] && (rm == 15)) ||
                   (!store_case[0] && !instruction[22] &&
                    ((rm == rd) || (rm == ((rd + 1) & 15)))) ||
                   (rd == 14));
                #1ps;
                assert (arm946_decode_match && arm946_profile_legal);
                assert (arm946_undefined_encoding == expected_undefined);
                assert (arm946_unpredictable_encoding ==
                        expected_unpredictable);
                assert (arm946_encoding_valid ==
                        (!expected_undefined && !expected_unpredictable));
                assert (arm946_transfer_load == !store_case[0]);
                assert (arm946_writeback == expected_writeback);
                assert (arm946_base_register == rn[3:0]);
                assert (arm946_first_data_register == rd[3:0]);
                assert (arm946_second_data_register ==
                        (rd[3:0] + 4'd1));
                assert (arm946_index_register == rm[3:0]);
                cases_checked++;
              end
            end
          end
        end
      end
    end

    // REQ: ARM946ES-ARM-DOUBLEWORD-ALIGNMENT-001
    for (int unsigned store_case = 0; store_case < 2; store_case++) begin
      for (int unsigned low_case = 0; low_case < 8; low_case++) begin
        instruction = store_case[0] ? 32'he1c1_20f0 : 32'he1c1_20d0;
        base_value = 32'h2000_0000 | low_case;
        #1ps;
        assert (arm946_encoding_valid);
        assert (arm946_unaligned_access_unpredictable == (low_case != 0));
        cases_checked++;
      end
    end

    assert (cases_checked == 327_888);
    $display("PASS profile-separated ARM doubleword transfer decode (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
