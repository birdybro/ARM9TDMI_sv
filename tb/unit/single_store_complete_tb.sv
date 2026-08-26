module single_store_complete_tb;
  logic        completion_valid;
  logic        precise_data_abort;
  logic        base_writeback_pending;
  logic [3:0]  base_register;
  logic [31:0] base_writeback_value;
  logic        data_abort_taken;
  logic        base_writeback_valid;
  logic [3:0]  base_writeback_register;
  logic [31:0] committed_base_writeback_value;
  logic        base_restored_on_abort;
  int unsigned cases_checked;

  arm9_single_store_complete dut (.*);

  initial begin
    cases_checked = 0;
    completion_valid = 1'b0;
    precise_data_abort = 1'b0;
    base_writeback_pending = 1'b0;
    base_register = 4'h0;
    base_writeback_value = '0;

    // REQ: COMMON-SINGLE-STORE-DATA-ABORT-001
    for (int unsigned valid_case = 0; valid_case < 2; valid_case++) begin
      for (int unsigned abort_case = 0; abort_case < 2; abort_case++) begin
        for (int unsigned writeback_case = 0; writeback_case < 2;
             writeback_case++) begin
          for (int unsigned register_case = 0; register_case < 16;
               register_case++) begin
            completion_valid = valid_case[0];
            precise_data_abort = abort_case[0];
            base_writeback_pending = writeback_case[0];
            base_register = register_case[3:0];
            base_writeback_value = 32'h4000_0000 |
                                   (32'(register_case) << 4);
            #1ps;

            assert (data_abort_taken ==
                    (valid_case[0] && abort_case[0]));
            assert (base_writeback_valid ==
                    (valid_case[0] && !abort_case[0] &&
                     writeback_case[0]));
            assert (base_restored_on_abort ==
                    (valid_case[0] && abort_case[0] &&
                     writeback_case[0]));
            assert (base_writeback_register == base_register);
            assert (committed_base_writeback_value ==
                    base_writeback_value);
            cases_checked++;
          end
        end
      end
    end

    assert (cases_checked == 128);
    $display("PASS base-restored single-store completion (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
