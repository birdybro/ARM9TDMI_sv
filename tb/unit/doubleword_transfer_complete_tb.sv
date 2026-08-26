module doubleword_transfer_complete_tb;
  logic        completion_valid;
  logic        precise_data_abort;
  logic        transfer_load;
  logic [3:0]  first_data_register;
  logic [3:0]  second_data_register;
  logic [31:0] first_load_value;
  logic [31:0] second_load_value;
  logic        base_writeback_pending;
  logic [3:0]  base_register;
  logic [31:0] base_writeback_value;
  logic        data_abort_taken;
  logic        destination_values_unpredictable_on_abort;
  logic        first_destination_write_valid;
  logic [3:0]  first_destination_write_register;
  logic [31:0] first_destination_write_value;
  logic        second_destination_write_valid;
  logic [3:0]  second_destination_write_register;
  logic [31:0] second_destination_write_value;
  logic        base_writeback_valid;
  logic [3:0]  base_writeback_register;
  logic [31:0] committed_base_writeback_value;
  logic        base_restored_on_abort;
  int unsigned cases_checked;

  arm9_doubleword_transfer_complete dut (.*);

  initial begin
    logic expected_success;

    completion_valid = 1'b0;
    precise_data_abort = 1'b0;
    transfer_load = 1'b0;
    first_data_register = 4'h0;
    second_data_register = 4'h1;
    first_load_value = '0;
    second_load_value = '0;
    base_writeback_pending = 1'b0;
    base_register = 4'he;
    base_writeback_value = '0;
    cases_checked = 0;

    // REQ: ARM946ES-ARM-DOUBLEWORD-COMPLETE-001
    // REQ: ARM946ES-ARM-DOUBLEWORD-DATA-ABORT-001
    for (int unsigned load_case = 0; load_case < 2; load_case++) begin
      for (int unsigned valid_case = 0; valid_case < 2; valid_case++) begin
        for (int unsigned abort_case = 0; abort_case < 2; abort_case++) begin
          for (int unsigned writeback_case = 0; writeback_case < 2;
               writeback_case++) begin
            for (int unsigned register_case = 0; register_case < 7;
                 register_case++) begin
              completion_valid = valid_case[0];
              precise_data_abort = abort_case[0];
              transfer_load = load_case[0];
              first_data_register = register_case[3:0] << 1;
              second_data_register = first_data_register + 4'd1;
              first_load_value = 32'h0123_0000 | 32'(register_case);
              second_load_value = 32'h89ab_0000 | 32'(register_case);
              base_writeback_pending = writeback_case[0];
              base_register = 4'he;
              base_writeback_value = 32'h4000_0000 |
                                     (32'(register_case) << 3);
              expected_success = valid_case[0] && !abort_case[0];
              #1ps;

              assert (data_abort_taken ==
                      (valid_case[0] && abort_case[0]));
              assert (destination_values_unpredictable_on_abort ==
                      (valid_case[0] && abort_case[0] && load_case[0]));
              assert (first_destination_write_valid ==
                      (expected_success && load_case[0]));
              assert (second_destination_write_valid ==
                      (expected_success && load_case[0]));
              assert (first_destination_write_register ==
                      first_data_register);
              assert (first_destination_write_value == first_load_value);
              assert (second_destination_write_register ==
                      second_data_register);
              assert (second_destination_write_value == second_load_value);
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

    assert (cases_checked == 112);
    $display("PASS ARM946E-S doubleword completion and abort intent (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
