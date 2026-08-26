module misc_load_data_format_tb;
  import arm9_isa_pkg::*;

  arm9_misc_transfer_kind_e transfer_kind;
  logic [7:0]               selected_byte_value;
  logic [15:0]              selected_halfword_value;
  logic                     format_valid;
  logic [31:0]              load_value;
  int unsigned              cases_checked;

  arm9_misc_load_data_format dut (.*);

  initial begin
    cases_checked = 0;
    transfer_kind = ARM9_MISC_TRANSFER_STRH;
    selected_byte_value = '0;
    selected_halfword_value = '0;

    transfer_kind = ARM9_MISC_TRANSFER_STRH;
    #1ps;
    assert (!format_valid && (load_value == 32'b0));
    cases_checked++;

    // REQ: COMMON-ARM-LDRH-ZERO-EXTEND-001
    // REQ: COMMON-ARM-LDRSH-SIGN-EXTEND-001
    for (int unsigned halfword_case = 0; halfword_case < 65_536;
         halfword_case++) begin
      selected_halfword_value = halfword_case[15:0];

      transfer_kind = ARM9_MISC_TRANSFER_LDRH;
      #1ps;
      assert (format_valid);
      assert (load_value == {16'b0, selected_halfword_value});
      cases_checked++;

      transfer_kind = ARM9_MISC_TRANSFER_LDRSH;
      #1ps;
      assert (format_valid);
      assert (load_value ==
              {{16{selected_halfword_value[15]}},
               selected_halfword_value});
      cases_checked++;
    end

    // REQ: COMMON-ARM-LDRSB-SIGN-EXTEND-001
    for (int unsigned byte_case = 0; byte_case < 256; byte_case++) begin
      selected_byte_value = byte_case[7:0];
      transfer_kind = ARM9_MISC_TRANSFER_LDRSB;
      #1ps;
      assert (format_valid);
      assert (load_value ==
              {{24{selected_byte_value[7]}}, selected_byte_value});
      cases_checked++;
    end

    assert (cases_checked == 131_329);
    $display("PASS exhaustive miscellaneous-load data formatting (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
