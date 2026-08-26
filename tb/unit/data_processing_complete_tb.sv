module data_processing_complete_tb;
  import arm9_arch_pkg::*;

  logic result_write_pending;
  logic flags_write_pending;
  logic [3:0] destination_register;
  logic [31:0] result_value;
  logic negative_value;
  logic zero_value;
  logic carry_value;
  logic overflow_value;
  arm9_mode_e current_mode;
  logic [31:0] current_spsr_value;
  logic pc_destination;
  logic unpredictable_operation;
  logic register_write_valid;
  logic [3:0] register_write_register;
  logic [31:0] register_write_value;
  logic nzcv_write_valid;
  logic negative_write_value;
  logic zero_write_value;
  logic carry_write_value;
  logic overflow_write_value;
  logic pc_write_valid;
  logic [31:0] pc_write_value;
  logic pc_write_thumb_state;
  logic cpsr_restore_valid;
  logic [31:0] cpsr_restore_value;
  logic pipeline_flush_request;
  int unsigned cases_checked;

  arm9_data_processing_complete dut (.*);

  function automatic arm9_mode_e mode_for_case(input int unsigned value);
    case (value)
      0: return ARM9_MODE_USER;
      1: return ARM9_MODE_FIQ;
      2: return ARM9_MODE_IRQ;
      3: return ARM9_MODE_SUPERVISOR;
      4: return ARM9_MODE_ABORT;
      5: return ARM9_MODE_UNDEFINED;
      default: return ARM9_MODE_SYSTEM;
    endcase
  endfunction

  initial begin
    logic expected_pc_destination;
    logic expected_has_spsr;
    logic expected_return;
    logic expected_thumb;
    logic expected_alignment_error;
    logic expected_unpredictable;
    logic expected_pc_write;

    result_write_pending = 1'b0;
    flags_write_pending = 1'b0;
    destination_register = 4'b0;
    result_value = 32'b0;
    negative_value = 1'b0;
    zero_value = 1'b0;
    carry_value = 1'b0;
    overflow_value = 1'b0;
    current_mode = ARM9_MODE_SUPERVISOR;
    current_spsr_value = 32'b0;
    cases_checked = 0;

    // REQ: COMMON-ARM-DATA-COMPLETE-001
    // REQ: COMMON-ARM-DATA-PC-WRITE-001
    // REQ: COMMON-ARM-DATA-EXCEPTION-RETURN-001
    for (int unsigned result_case = 0; result_case < 2;
         result_case++) begin
      for (int unsigned flags_case = 0; flags_case < 2;
           flags_case++) begin
        for (int unsigned destination_case = 0; destination_case < 16;
             destination_case++) begin
          for (int unsigned mode_case = 0; mode_case < 7;
               mode_case++) begin
            for (int unsigned spsr_t_case = 0; spsr_t_case < 2;
                 spsr_t_case++) begin
              for (int unsigned low_case = 0; low_case < 4;
                   low_case++) begin
                result_write_pending = result_case[0];
                flags_write_pending = flags_case[0];
                destination_register = destination_case[3:0];
                result_value = 32'h8000_1000 | low_case;
                negative_value = destination_case[3];
                zero_value = destination_case[2];
                carry_value = destination_case[1];
                overflow_value = destination_case[0];
                current_mode = mode_for_case(mode_case);
                current_spsr_value = 32'hf800_00d3;
                current_spsr_value[5] = spsr_t_case[0];

                expected_pc_destination = destination_case == 15;
                expected_has_spsr = (mode_case != 0) && (mode_case != 6);
                expected_return = result_case[0] && flags_case[0] &&
                                  expected_pc_destination;
                expected_thumb = expected_return && expected_has_spsr &&
                                 spsr_t_case[0];
                expected_alignment_error = result_case[0] &&
                  expected_pc_destination && !expected_thumb &&
                  (low_case != 0);
                expected_unpredictable = result_case[0] &&
                  expected_pc_destination &&
                  ((expected_return && !expected_has_spsr) ||
                   expected_alignment_error);
                expected_pc_write = result_case[0] &&
                                    expected_pc_destination &&
                                    !expected_unpredictable;
                #1ps;

                assert (pc_destination == expected_pc_destination);
                assert (unpredictable_operation == expected_unpredictable);
                assert (register_write_valid ==
                        (result_case[0] && !expected_pc_destination));
                assert (register_write_register == destination_case[3:0]);
                assert (register_write_value == result_value);
                assert (nzcv_write_valid ==
                        (flags_case[0] && !expected_pc_destination));
                assert (negative_write_value == negative_value);
                assert (zero_write_value == zero_value);
                assert (carry_write_value == carry_value);
                assert (overflow_write_value == overflow_value);
                assert (pc_write_valid == expected_pc_write);
                assert (pipeline_flush_request == expected_pc_write);
                assert (cpsr_restore_valid ==
                        (expected_pc_write && expected_return));
                assert (cpsr_restore_value == current_spsr_value);
                assert (pc_write_thumb_state == expected_thumb);
                if (expected_thumb) begin
                  assert (pc_write_value == {result_value[31:1], 1'b0});
                end else begin
                  assert (pc_write_value == result_value);
                end
                cases_checked++;
              end
            end
          end
        end
      end
    end

    assert (cases_checked == 3_584) else begin
      $error("case-count expected=3584 actual=%0d", cases_checked);
    end
    $display("PASS ARM data-processing completion and PC returns (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
