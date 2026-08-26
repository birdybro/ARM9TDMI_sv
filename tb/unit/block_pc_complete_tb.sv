module block_pc_complete_tb;
  import arm9_profile_pkg::*;

  logic        completion_valid;
  logic        precise_data_abort;
  logic        pc_load_pending;
  logic        restore_cpsr_pending;
  logic [31:0] loaded_pc_value;
  logic        spsr_thumb_state;
  logic        arm946_disable_loading_tbit;

  logic        tdmi_data_abort_taken;
  logic        tdmi_pc_write_valid;
  logic [31:0] tdmi_pc_write_value;
  logic        tdmi_pc_write_thumb_state;
  logic        tdmi_cpsr_restore_valid;
  logic        tdmi_pc_state_from_spsr;
  logic        tdmi_pc_load_tbit_enabled;
  logic        tdmi_unpredictable_result;

  logic        arm946_data_abort_taken;
  logic        arm946_pc_write_valid;
  logic [31:0] arm946_pc_write_value;
  logic        arm946_pc_write_thumb_state;
  logic        arm946_cpsr_restore_valid;
  logic        arm946_pc_state_from_spsr;
  logic        arm946_pc_load_tbit_enabled;
  logic        arm946_unpredictable_result;
  int unsigned cases_checked;

  arm9_block_pc_complete #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .completion_valid,
    .precise_data_abort,
    .pc_load_pending,
    .restore_cpsr_pending,
    .loaded_pc_value,
    .spsr_thumb_state,
    .arm946_disable_loading_tbit,
    .data_abort_taken(tdmi_data_abort_taken),
    .pc_write_valid(tdmi_pc_write_valid),
    .pc_write_value(tdmi_pc_write_value),
    .pc_write_thumb_state(tdmi_pc_write_thumb_state),
    .cpsr_restore_valid(tdmi_cpsr_restore_valid),
    .pc_state_from_spsr(tdmi_pc_state_from_spsr),
    .pc_load_tbit_enabled(tdmi_pc_load_tbit_enabled),
    .unpredictable_result(tdmi_unpredictable_result)
  );

  arm9_block_pc_complete #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .completion_valid,
    .precise_data_abort,
    .pc_load_pending,
    .restore_cpsr_pending,
    .loaded_pc_value,
    .spsr_thumb_state,
    .arm946_disable_loading_tbit,
    .data_abort_taken(arm946_data_abort_taken),
    .pc_write_valid(arm946_pc_write_valid),
    .pc_write_value(arm946_pc_write_value),
    .pc_write_thumb_state(arm946_pc_write_thumb_state),
    .cpsr_restore_valid(arm946_cpsr_restore_valid),
    .pc_state_from_spsr(arm946_pc_state_from_spsr),
    .pc_load_tbit_enabled(arm946_pc_load_tbit_enabled),
    .unpredictable_result(arm946_unpredictable_result)
  );

  initial begin
    logic expected_success;
    logic expected_arm946_tbit;
    logic expected_arm946_unpredictable;

    completion_valid = 1'b0;
    precise_data_abort = 1'b0;
    pc_load_pending = 1'b0;
    restore_cpsr_pending = 1'b0;
    loaded_pc_value = 32'b0;
    spsr_thumb_state = 1'b0;
    arm946_disable_loading_tbit = 1'b0;
    cases_checked = 0;

    // REQ: ARM9TDMI-LDM-PC-SEMANTICS-001
    // REQ: ARM946ES-LDM-PC-SEMANTICS-001
    // REQ: COMMON-ARM-LDM-EXCEPTION-RETURN-001
    // REQ: COMMON-ARM-LDM-PC-DATA-ABORT-001
    for (int unsigned valid_case = 0; valid_case < 2; valid_case++) begin
      for (int unsigned abort_case = 0; abort_case < 2; abort_case++) begin
        for (int unsigned pc_case = 0; pc_case < 2; pc_case++) begin
          for (int unsigned restore_case = 0; restore_case < 2;
               restore_case++) begin
            for (int unsigned spsr_t_case = 0; spsr_t_case < 2;
                 spsr_t_case++) begin
              for (int unsigned disable_case = 0; disable_case < 2;
                   disable_case++) begin
                for (int unsigned low_case = 0; low_case < 4;
                     low_case++) begin
                  if (restore_case[0] && !pc_case[0]) begin
                    continue;
                  end
                  completion_valid = valid_case[0];
                  precise_data_abort = abort_case[0];
                  pc_load_pending = pc_case[0];
                  restore_cpsr_pending = restore_case[0];
                  loaded_pc_value = 32'h8000_1000 | low_case;
                  spsr_thumb_state = spsr_t_case[0];
                  arm946_disable_loading_tbit = disable_case[0];
                  expected_success = valid_case[0] && !abort_case[0] &&
                                     pc_case[0];
                  expected_arm946_tbit = !restore_case[0] &&
                                         !disable_case[0];
                  expected_arm946_unpredictable = expected_success &&
                    expected_arm946_tbit && (low_case == 2);
                  #1ps;

                  assert (tdmi_data_abort_taken ==
                          (valid_case[0] && abort_case[0]));
                  assert (arm946_data_abort_taken ==
                          tdmi_data_abort_taken);
                  assert (tdmi_pc_state_from_spsr == restore_case[0]);
                  assert (arm946_pc_state_from_spsr == restore_case[0]);
                  assert (!tdmi_pc_load_tbit_enabled);
                  assert (arm946_pc_load_tbit_enabled ==
                          expected_arm946_tbit);
                  assert (!tdmi_unpredictable_result);
                  assert (arm946_unpredictable_result ==
                          expected_arm946_unpredictable);
                  assert (tdmi_pc_write_valid == expected_success);
                  assert (arm946_pc_write_valid ==
                          (expected_success &&
                           !expected_arm946_unpredictable));
                  assert (tdmi_cpsr_restore_valid ==
                          (expected_success && restore_case[0]));
                  assert (arm946_cpsr_restore_valid ==
                          (expected_success && restore_case[0]));

                  if (restore_case[0]) begin
                    assert (tdmi_pc_write_thumb_state == spsr_t_case[0]);
                    assert (arm946_pc_write_thumb_state == spsr_t_case[0]);
                    if (spsr_t_case[0]) begin
                      assert (tdmi_pc_write_value ==
                              {loaded_pc_value[31:1], 1'b0});
                    end else begin
                      assert (tdmi_pc_write_value ==
                              {loaded_pc_value[31:2], 2'b00});
                    end
                    assert (arm946_pc_write_value == tdmi_pc_write_value);
                  end else begin
                    assert (!tdmi_pc_write_thumb_state);
                    assert (tdmi_pc_write_value ==
                            {loaded_pc_value[31:2], 2'b00});
                    if (expected_arm946_tbit) begin
                      assert (arm946_pc_write_thumb_state ==
                              loaded_pc_value[0]);
                      assert (arm946_pc_write_value ==
                              {loaded_pc_value[31:1], 1'b0});
                    end else begin
                      assert (!arm946_pc_write_thumb_state);
                      assert (arm946_pc_write_value ==
                              {loaded_pc_value[31:2], 2'b00});
                    end
                  end
                  cases_checked++;
                end
              end
            end
          end
        end
      end
    end

    assert (cases_checked == 192);
    $display("PASS profile-specific ARM LDM-to-PC completion (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
