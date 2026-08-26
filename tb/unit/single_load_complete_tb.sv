module single_load_complete_tb;
  import arm9_profile_pkg::*;

  logic        completion_valid;
  logic        data_abort;
  logic [3:0]  data_register;
  logic [31:0] load_value;
  logic        base_writeback_pending;
  logic [3:0]  base_register;
  logic [31:0] base_writeback_value;
  logic        arm946_disable_loading_tbit;

  logic        tdmi_data_abort_taken;
  logic        tdmi_destination_write_valid;
  logic [3:0]  tdmi_destination_write_register;
  logic [31:0] tdmi_destination_write_value;
  logic        tdmi_base_writeback_valid;
  logic [3:0]  tdmi_base_writeback_register;
  logic [31:0] tdmi_committed_base_writeback_value;
  logic        tdmi_base_restored_on_abort;
  logic        tdmi_pc_destination;
  logic        tdmi_pc_write_valid;
  logic [31:0] tdmi_pc_write_value;
  logic        tdmi_pc_write_thumb_state;
  logic        tdmi_pc_load_tbit_enabled;
  logic        tdmi_unpredictable_result;

  logic        arm946_data_abort_taken;
  logic        arm946_destination_write_valid;
  logic [3:0]  arm946_destination_write_register;
  logic [31:0] arm946_destination_write_value;
  logic        arm946_base_writeback_valid;
  logic [3:0]  arm946_base_writeback_register;
  logic [31:0] arm946_committed_base_writeback_value;
  logic        arm946_base_restored_on_abort;
  logic        arm946_pc_destination;
  logic        arm946_pc_write_valid;
  logic [31:0] arm946_pc_write_value;
  logic        arm946_pc_write_thumb_state;
  logic        arm946_pc_load_tbit_enabled;
  logic        arm946_unpredictable_result;

  int unsigned cases_checked;

  arm9_single_load_complete #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .completion_valid,
    .data_abort,
    .data_register,
    .load_value,
    .base_writeback_pending,
    .base_register,
    .base_writeback_value,
    .arm946_disable_loading_tbit,
    .data_abort_taken(tdmi_data_abort_taken),
    .destination_write_valid(tdmi_destination_write_valid),
    .destination_write_register(tdmi_destination_write_register),
    .destination_write_value(tdmi_destination_write_value),
    .base_writeback_valid(tdmi_base_writeback_valid),
    .base_writeback_register(tdmi_base_writeback_register),
    .committed_base_writeback_value(tdmi_committed_base_writeback_value),
    .base_restored_on_abort(tdmi_base_restored_on_abort),
    .pc_destination(tdmi_pc_destination),
    .pc_write_valid(tdmi_pc_write_valid),
    .pc_write_value(tdmi_pc_write_value),
    .pc_write_thumb_state(tdmi_pc_write_thumb_state),
    .pc_load_tbit_enabled(tdmi_pc_load_tbit_enabled),
    .unpredictable_result(tdmi_unpredictable_result)
  );

  arm9_single_load_complete #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .completion_valid,
    .data_abort,
    .data_register,
    .load_value,
    .base_writeback_pending,
    .base_register,
    .base_writeback_value,
    .arm946_disable_loading_tbit,
    .data_abort_taken(arm946_data_abort_taken),
    .destination_write_valid(arm946_destination_write_valid),
    .destination_write_register(arm946_destination_write_register),
    .destination_write_value(arm946_destination_write_value),
    .base_writeback_valid(arm946_base_writeback_valid),
    .base_writeback_register(arm946_base_writeback_register),
    .committed_base_writeback_value(arm946_committed_base_writeback_value),
    .base_restored_on_abort(arm946_base_restored_on_abort),
    .pc_destination(arm946_pc_destination),
    .pc_write_valid(arm946_pc_write_valid),
    .pc_write_value(arm946_pc_write_value),
    .pc_write_thumb_state(arm946_pc_write_thumb_state),
    .pc_load_tbit_enabled(arm946_pc_load_tbit_enabled),
    .unpredictable_result(arm946_unpredictable_result)
  );

  task automatic check_common_outputs(
    input logic expected_abort,
    input logic expected_destination_write,
    input logic expected_pc_destination,
    input logic expected_base_restored
  );
    assert (tdmi_data_abort_taken == expected_abort);
    assert (arm946_data_abort_taken == expected_abort);
    assert (tdmi_destination_write_valid == expected_destination_write);
    assert (arm946_destination_write_valid == expected_destination_write);
    assert (tdmi_pc_destination == expected_pc_destination);
    assert (arm946_pc_destination == expected_pc_destination);
    assert (tdmi_base_restored_on_abort == expected_base_restored);
    assert (arm946_base_restored_on_abort == expected_base_restored);
    assert (tdmi_destination_write_register == data_register);
    assert (arm946_destination_write_register == data_register);
    assert (tdmi_destination_write_value == load_value);
    assert (arm946_destination_write_value == load_value);
    assert (tdmi_base_writeback_register == base_register);
    assert (arm946_base_writeback_register == base_register);
    assert (tdmi_committed_base_writeback_value == base_writeback_value);
    assert (arm946_committed_base_writeback_value == base_writeback_value);
  endtask

  initial begin
    cases_checked = 0;
    completion_valid = 1'b0;
    data_abort = 1'b0;
    data_register = 4'h0;
    load_value = '0;
    base_writeback_pending = 1'b0;
    base_register = 4'h1;
    base_writeback_value = 32'h1000_0004;
    arm946_disable_loading_tbit = 1'b0;

    // REQ: COMMON-SINGLE-LOAD-DATA-ABORT-001
    // REQ: ARM9TDMI-LDR-PC-SEMANTICS-001
    // REQ: ARM946ES-LDR-PC-SEMANTICS-001
    for (int unsigned valid_case = 0; valid_case < 2; valid_case++) begin
      for (int unsigned abort_case = 0; abort_case < 2; abort_case++) begin
        for (int unsigned register_case = 0; register_case < 16;
             register_case++) begin
          for (int unsigned writeback_case = 0; writeback_case < 2;
               writeback_case++) begin
            for (int unsigned disable_case = 0; disable_case < 2;
                 disable_case++) begin
              for (int unsigned low_case = 0; low_case < 4; low_case++) begin
                completion_valid = valid_case[0];
                data_abort = abort_case[0];
                data_register = register_case[3:0];
                load_value = 32'h8000_1000 | low_case;
                base_writeback_pending = writeback_case[0];
                base_register = 4'h6;
                base_writeback_value = 32'h2468_ace0;
                arm946_disable_loading_tbit = disable_case[0];
                #1ps;

                check_common_outputs(
                  valid_case[0] && abort_case[0],
                  valid_case[0] && !abort_case[0] &&
                    (register_case != 15),
                  register_case == 15,
                  valid_case[0] && abort_case[0] && writeback_case[0]
                );

                assert (!tdmi_pc_load_tbit_enabled);
                assert (!tdmi_unpredictable_result);
                assert (tdmi_pc_write_value ==
                        {load_value[31:2], 2'b00});
                assert (!tdmi_pc_write_thumb_state);
                assert (tdmi_pc_write_valid ==
                        (valid_case[0] && !abort_case[0] &&
                         (register_case == 15)));
                assert (tdmi_base_writeback_valid ==
                        (valid_case[0] && !abort_case[0] &&
                         writeback_case[0]));

                assert (arm946_pc_load_tbit_enabled == !disable_case[0]);
                if (!disable_case[0] && (low_case == 2)) begin
                  assert (arm946_unpredictable_result ==
                          (valid_case[0] && !abort_case[0] &&
                           (register_case == 15)));
                  assert (!arm946_pc_write_valid);
                  if (register_case == 15) begin
                    assert (!arm946_base_writeback_valid);
                  end
                end else begin
                  assert (!arm946_unpredictable_result);
                  assert (arm946_pc_write_valid ==
                          (valid_case[0] && !abort_case[0] &&
                           (register_case == 15)));
                  assert (arm946_base_writeback_valid ==
                          (valid_case[0] && !abort_case[0] &&
                           writeback_case[0]));
                end

                if (!disable_case[0]) begin
                  assert (arm946_pc_write_value ==
                          {load_value[31:1], 1'b0});
                  assert (arm946_pc_write_thumb_state == load_value[0]);
                end else begin
                  assert (arm946_pc_write_value ==
                          {load_value[31:2], 2'b00});
                  assert (!arm946_pc_write_thumb_state);
                end
                cases_checked++;
              end
            end
          end
        end
      end
    end

    assert (cases_checked == 1_024);
    $display("PASS profile-specific single-load completion (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
