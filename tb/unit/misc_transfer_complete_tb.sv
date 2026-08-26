module misc_transfer_complete_tb;
  import arm9_isa_pkg::*;

  logic                                  completion_valid;
  logic                                  precise_data_abort;
  arm9_misc_transfer_kind_e              transfer_kind;
  logic [3:0]                            data_register;
  logic [7:0]                            selected_byte_value;
  logic [15:0]                           selected_halfword_value;
  logic                                  base_writeback_pending;
  logic [3:0]                            base_register;
  logic [31:0]                           base_writeback_value;
  logic                                  data_abort_taken;
  logic                                  destination_write_valid;
  logic [3:0]                            destination_write_register;
  logic [31:0]                           destination_write_value;
  logic                                  base_writeback_valid;
  logic [3:0]                            base_writeback_register;
  logic [31:0]                           committed_base_writeback_value;
  logic                                  base_restored_on_abort;
  int unsigned                           cases_checked;

  arm9_misc_transfer_complete dut (.*);

  function automatic logic [31:0] expected_load_value(
    input arm9_misc_transfer_kind_e kind,
    input logic [7:0] byte_value,
    input logic [15:0] halfword_value
  );
    case (kind)
      ARM9_MISC_TRANSFER_LDRH:
        return {16'b0, halfword_value};
      ARM9_MISC_TRANSFER_LDRSB:
        return {{24{byte_value[7]}}, byte_value};
      ARM9_MISC_TRANSFER_LDRSH:
        return {{16{halfword_value[15]}}, halfword_value};
      default: return 32'b0;
    endcase
  endfunction

  initial begin
    logic expected_success;
    logic expected_load;

    completion_valid = 1'b0;
    precise_data_abort = 1'b0;
    transfer_kind = ARM9_MISC_TRANSFER_STRH;
    data_register = 4'h0;
    selected_byte_value = '0;
    selected_halfword_value = '0;
    base_writeback_pending = 1'b0;
    base_register = 4'h1;
    base_writeback_value = '0;
    cases_checked = 0;

    // REQ: COMMON-ARM-MISC-TRANSFER-COMPLETE-001
    // REQ: COMMON-ARM-MISC-TRANSFER-DATA-ABORT-001
    for (int unsigned operation_case = 0; operation_case < 4;
         operation_case++) begin
      for (int unsigned valid_case = 0; valid_case < 2; valid_case++) begin
        for (int unsigned abort_case = 0; abort_case < 2; abort_case++) begin
          for (int unsigned writeback_case = 0; writeback_case < 2;
               writeback_case++) begin
            for (int unsigned register_case = 0; register_case < 15;
                 register_case++) begin
              transfer_kind = arm9_misc_transfer_kind_e'(operation_case[1:0]);
              completion_valid = valid_case[0];
              precise_data_abort = abort_case[0];
              base_writeback_pending = writeback_case[0];
              data_register = register_case[3:0];
              selected_byte_value = 8'h80 ^ register_case[7:0];
              selected_halfword_value = 16'h8000 ^
                                        (16'(register_case) << 4);
              base_register = 4'he;
              base_writeback_value = 32'h3456_7800 |
                                     32'(register_case);
              expected_success = valid_case[0] && !abort_case[0];
              expected_load = operation_case != 0;
              #1ps;

              assert (data_abort_taken ==
                      (valid_case[0] && abort_case[0]));
              assert (destination_write_valid ==
                      (expected_success && expected_load));
              assert (destination_write_register == data_register);
              assert (destination_write_value == expected_load_value(
                transfer_kind, selected_byte_value, selected_halfword_value
              ));
              assert (base_writeback_valid ==
                      (expected_success && writeback_case[0]));
              assert (base_writeback_register == base_register);
              assert (committed_base_writeback_value ==
                      base_writeback_value);
              assert (base_restored_on_abort ==
                      (valid_case[0] && abort_case[0] &&
                       writeback_case[0]));
              cases_checked++;
            end
          end
        end
      end
    end

    assert (cases_checked == 480);
    $display("PASS common ARM miscellaneous-transfer completion (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
