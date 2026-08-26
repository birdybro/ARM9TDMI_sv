module store_data_select_tb;
  import arm9_profile_pkg::*;

  logic [31:0] instruction_address;
  logic [3:0]  data_register;
  logic        byte_transfer;
  logic [31:0] register_value;
  logic [31:0] unresolved_profile_pc_value;

  logic [31:0] tdmi_store_value;
  logic [7:0]  tdmi_store_byte_value;
  logic        tdmi_pc_store_special_case;
  logic        tdmi_pc_store_value_documented;
  logic        tdmi_pc_store_value_unresolved;

  logic [31:0] arm946_store_value;
  logic [7:0]  arm946_store_byte_value;
  logic        arm946_pc_store_special_case;
  logic        arm946_pc_store_value_documented;
  logic        arm946_pc_store_value_unresolved;

  int unsigned cases_checked;

  arm9_store_data_select #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .instruction_address,
    .data_register,
    .byte_transfer,
    .register_value,
    .unresolved_profile_pc_value,
    .store_value(tdmi_store_value),
    .store_byte_value(tdmi_store_byte_value),
    .pc_store_special_case(tdmi_pc_store_special_case),
    .pc_store_value_documented(tdmi_pc_store_value_documented),
    .pc_store_value_unresolved(tdmi_pc_store_value_unresolved)
  );

  arm9_store_data_select #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .instruction_address,
    .data_register,
    .byte_transfer,
    .register_value,
    .unresolved_profile_pc_value,
    .store_value(arm946_store_value),
    .store_byte_value(arm946_store_byte_value),
    .pc_store_special_case(arm946_pc_store_special_case),
    .pc_store_value_documented(arm946_pc_store_value_documented),
    .pc_store_value_unresolved(arm946_pc_store_value_unresolved)
  );

  initial begin
    cases_checked = 0;
    instruction_address = '0;
    data_register = '0;
    byte_transfer = 1'b0;
    register_value = '0;
    unresolved_profile_pc_value = '0;

    // REQ: ARM9TDMI-PC-STORE-OFFSET-001
    // REQ: ARM946ES-PC-STORE-OFFSET-001
    for (int unsigned address_case = 0; address_case < 256;
         address_case++) begin
      for (int unsigned register_case = 0; register_case < 16;
           register_case++) begin
        for (int unsigned byte_case = 0; byte_case < 2; byte_case++) begin
          instruction_address = 32'h0100_0000 + (address_case << 2);
          data_register = register_case[3:0];
          byte_transfer = byte_case[0];
          register_value = 32'h1357_9bdf ^
                           (32'(address_case) << 16) ^
                           (32'(register_case) << 8) ^ 32'(byte_case);
          unresolved_profile_pc_value = 32'ha5a5_0000 ^
                                        32'(address_case);
          #1ps;

          if ((register_case == 15) && (byte_case == 0)) begin
            assert (tdmi_pc_store_special_case);
            assert (tdmi_pc_store_value_documented);
            assert (!tdmi_pc_store_value_unresolved);
            assert (tdmi_store_value == instruction_address + 32'd12);

            assert (arm946_pc_store_special_case);
            assert (!arm946_pc_store_value_documented);
            assert (arm946_pc_store_value_unresolved);
            assert (arm946_store_value == unresolved_profile_pc_value);
          end else begin
            assert (!tdmi_pc_store_special_case);
            assert (!tdmi_pc_store_value_documented);
            assert (!tdmi_pc_store_value_unresolved);
            assert (tdmi_store_value == register_value);

            assert (!arm946_pc_store_special_case);
            assert (!arm946_pc_store_value_documented);
            assert (!arm946_pc_store_value_unresolved);
            assert (arm946_store_value == register_value);
          end

          assert (tdmi_store_byte_value == tdmi_store_value[7:0]);
          assert (arm946_store_byte_value == arm946_store_value[7:0]);
          cases_checked++;
        end
      end
    end

    instruction_address = 32'hffff_fff8;
    data_register = 4'hf;
    byte_transfer = 1'b0;
    unresolved_profile_pc_value = 32'h0123_4567;
    #1ps;
    assert (tdmi_store_value == 32'h0000_0004);
    assert (arm946_store_value == 32'h0123_4567);
    cases_checked++;

    assert (cases_checked == 8_193);
    $display("PASS profile-specific ARM store-data selection (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
