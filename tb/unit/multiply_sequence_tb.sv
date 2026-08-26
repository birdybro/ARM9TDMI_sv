module multiply_sequence_tb;
  import arm9_profile_pkg::*;
  import arm9_isa_pkg::*;
  import arm9_timing_pkg::*;

  logic clk;
  logic reset;
  logic start;
  arm9_multiply_kind_e multiply_kind;
  logic [23:0] multiplier_operand_high;
  logic set_flags;
  logic qualified_result_dependency;

  logic tdmi_ready;
  logic tdmi_request_accepted;
  logic tdmi_request_error;
  logic tdmi_busy;
  logic tdmi_cycle_valid;
  logic [3:0] tdmi_cycle_number;
  logic [3:0] tdmi_cycle_total;
  arm9_multiply_kind_e tdmi_active_multiply_kind;
  logic tdmi_active_set_flags;
  logic tdmi_active_qualified_dependency;
  logic tdmi_active_uses_early_termination;
  logic [2:0] tdmi_active_early_termination_class;
  logic tdmi_active_dependency_interlock;
  arm9_bus_cycle_e tdmi_instruction_cycle_type;
  arm9_bus_cycle_e tdmi_data_cycle_type;
  logic tdmi_instruction_order_documented;
  logic tdmi_data_order_documented;
  logic [3:0] tdmi_instruction_sequential_cycles;
  logic [3:0] tdmi_instruction_internal_cycles;
  logic [3:0] tdmi_data_internal_cycles;
  logic tdmi_operation_complete;

  logic arm946_ready;
  logic arm946_request_accepted;
  logic arm946_request_error;
  logic arm946_busy;
  logic arm946_cycle_valid;
  logic [3:0] arm946_cycle_number;
  logic [3:0] arm946_cycle_total;
  arm9_multiply_kind_e arm946_active_multiply_kind;
  logic arm946_active_set_flags;
  logic arm946_active_qualified_dependency;
  logic arm946_active_uses_early_termination;
  logic [2:0] arm946_active_early_termination_class;
  logic arm946_active_dependency_interlock;
  arm9_bus_cycle_e arm946_instruction_cycle_type;
  arm9_bus_cycle_e arm946_data_cycle_type;
  logic arm946_instruction_order_documented;
  logic arm946_data_order_documented;
  logic [3:0] arm946_instruction_sequential_cycles;
  logic [3:0] arm946_instruction_internal_cycles;
  logic [3:0] arm946_data_internal_cycles;
  logic arm946_operation_complete;
  int unsigned cycles_checked;
  int unsigned requests_checked;

  arm9_multiply_sequence #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .clk,
    .reset,
    .start,
    .multiply_kind,
    .multiplier_operand_high,
    .set_flags,
    .qualified_result_dependency,
    .ready(tdmi_ready),
    .request_accepted(tdmi_request_accepted),
    .request_error(tdmi_request_error),
    .busy(tdmi_busy),
    .cycle_valid(tdmi_cycle_valid),
    .cycle_number(tdmi_cycle_number),
    .cycle_total(tdmi_cycle_total),
    .active_multiply_kind(tdmi_active_multiply_kind),
    .active_set_flags(tdmi_active_set_flags),
    .active_qualified_dependency(tdmi_active_qualified_dependency),
    .active_uses_early_termination(
      tdmi_active_uses_early_termination
    ),
    .active_early_termination_class(
      tdmi_active_early_termination_class
    ),
    .active_dependency_interlock(tdmi_active_dependency_interlock),
    .instruction_cycle_type(tdmi_instruction_cycle_type),
    .data_cycle_type(tdmi_data_cycle_type),
    .instruction_order_documented(tdmi_instruction_order_documented),
    .data_order_documented(tdmi_data_order_documented),
    .instruction_sequential_cycles(tdmi_instruction_sequential_cycles),
    .instruction_internal_cycles(tdmi_instruction_internal_cycles),
    .data_internal_cycles(tdmi_data_internal_cycles),
    .operation_complete(tdmi_operation_complete)
  );

  arm9_multiply_sequence #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .clk,
    .reset,
    .start,
    .multiply_kind,
    .multiplier_operand_high,
    .set_flags,
    .qualified_result_dependency,
    .ready(arm946_ready),
    .request_accepted(arm946_request_accepted),
    .request_error(arm946_request_error),
    .busy(arm946_busy),
    .cycle_valid(arm946_cycle_valid),
    .cycle_number(arm946_cycle_number),
    .cycle_total(arm946_cycle_total),
    .active_multiply_kind(arm946_active_multiply_kind),
    .active_set_flags(arm946_active_set_flags),
    .active_qualified_dependency(arm946_active_qualified_dependency),
    .active_uses_early_termination(
      arm946_active_uses_early_termination
    ),
    .active_early_termination_class(
      arm946_active_early_termination_class
    ),
    .active_dependency_interlock(arm946_active_dependency_interlock),
    .instruction_cycle_type(arm946_instruction_cycle_type),
    .data_cycle_type(arm946_data_cycle_type),
    .instruction_order_documented(arm946_instruction_order_documented),
    .data_order_documented(arm946_data_order_documented),
    .instruction_sequential_cycles(arm946_instruction_sequential_cycles),
    .instruction_internal_cycles(arm946_instruction_internal_cycles),
    .data_internal_cycles(arm946_data_internal_cycles),
    .operation_complete(arm946_operation_complete)
  );

  initial begin
    clk = 1'b0;
    forever #5ns clk = !clk;
  end

  function automatic logic is_long_common(
    input arm9_multiply_kind_e kind
  );
    return (kind == ARM9_MULTIPLY_UMULL) ||
           (kind == ARM9_MULTIPLY_UMLAL) ||
           (kind == ARM9_MULTIPLY_SMULL) ||
           (kind == ARM9_MULTIPLY_SMLAL);
  endfunction

  function automatic logic [23:0] class_operand(
    input logic [2:0] early_class
  );
    case (early_class)
      3'd1: return 24'h000000;
      3'd2: return 24'h000001;
      3'd3: return 24'h000100;
      default: return 24'h010000;
    endcase
  endfunction

  function automatic logic [3:0] arm946_expected_cycles(
    input arm9_multiply_kind_e kind,
    input logic flags,
    input logic dependency
  );
    if (kind == ARM9_MULTIPLY_DSP_SHORT) begin
      return 4'd1 + {3'b000, dependency};
    end
    if (kind == ARM9_MULTIPLY_DSP_LONG) begin
      return 4'd2 + {3'b000, dependency};
    end
    if (flags) begin
      return is_long_common(kind) ? 4'd5 : 4'd4;
    end
    return (is_long_common(kind) ? 4'd3 : 4'd2) +
           {3'b000, dependency};
  endfunction

  task automatic check_tdmi_cycle(
    input arm9_multiply_kind_e kind,
    input logic flags,
    input logic dependency,
    input logic [2:0] early_class,
    input logic [3:0] cycle,
    input logic [3:0] total
  );
    assert (tdmi_busy && tdmi_cycle_valid && !tdmi_ready);
    assert ((tdmi_cycle_number == cycle) &&
            (tdmi_cycle_total == total));
    assert (tdmi_active_multiply_kind == kind);
    assert (tdmi_active_set_flags == flags);
    assert (tdmi_active_qualified_dependency == dependency);
    assert (tdmi_active_uses_early_termination);
    assert (tdmi_active_early_termination_class == early_class);
    assert (!tdmi_active_dependency_interlock);
    assert (!tdmi_instruction_order_documented);
    assert (tdmi_instruction_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (tdmi_data_order_documented);
    assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
    assert (tdmi_instruction_sequential_cycles == 4'd1);
    assert (tdmi_instruction_internal_cycles == total - 4'd1);
    assert (tdmi_data_internal_cycles == total);
    cycles_checked++;
  endtask

  task automatic check_arm946_cycle(
    input arm9_multiply_kind_e kind,
    input logic flags,
    input logic dependency,
    input logic expected_interlock,
    input logic [3:0] cycle,
    input logic [3:0] total
  );
    assert (arm946_busy && arm946_cycle_valid && !arm946_ready);
    assert ((arm946_cycle_number == cycle) &&
            (arm946_cycle_total == total));
    assert (arm946_active_multiply_kind == kind);
    assert (arm946_active_set_flags == flags);
    assert (arm946_active_qualified_dependency == dependency);
    assert (!arm946_active_uses_early_termination);
    assert (arm946_active_early_termination_class == 3'd0);
    assert (arm946_active_dependency_interlock == expected_interlock);
    assert (arm946_instruction_order_documented);
    assert (arm946_instruction_cycle_type ==
            ((cycle == total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                                ARM9_BUS_CYCLE_INTERNAL));
    assert (arm946_data_order_documented);
    assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
    assert (arm946_instruction_sequential_cycles == 4'd1);
    assert (arm946_instruction_internal_cycles == total - 4'd1);
    assert (arm946_data_internal_cycles == total);
    cycles_checked++;
  endtask

  task automatic run_common_request(
    input arm9_multiply_kind_e kind,
    input logic [2:0] early_class,
    input logic flags,
    input logic dependency
  );
    logic [3:0] tdmi_total;
    logic [3:0] arm946_total;
    logic [3:0] maximum_total;
    logic expected_arm946_interlock;

    tdmi_total = (is_long_common(kind) ? 4'd3 : 4'd2) +
                 {1'b0, early_class};
    arm946_total = arm946_expected_cycles(kind, flags, dependency);
    maximum_total = (tdmi_total > arm946_total) ? tdmi_total :
                                                  arm946_total;
    expected_arm946_interlock = !flags && dependency;

    @(negedge clk);
    assert (tdmi_ready && arm946_ready);
    multiply_kind = kind;
    multiplier_operand_high = class_operand(early_class);
    set_flags = flags;
    qualified_result_dependency = dependency;
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;
    assert (tdmi_request_accepted && !tdmi_request_error);
    assert (arm946_request_accepted && !arm946_request_error);
    requests_checked++;

    for (logic [3:0] cycle = 4'd1; cycle <= maximum_total; cycle++) begin
      if (cycle <= tdmi_total) begin
        check_tdmi_cycle(kind, flags, dependency, early_class,
                         cycle, tdmi_total);
      end else begin
        assert (!tdmi_busy && !tdmi_cycle_valid);
      end
      if (cycle <= arm946_total) begin
        check_arm946_cycle(kind, flags, dependency,
                           expected_arm946_interlock,
                           cycle, arm946_total);
      end else begin
        assert (!arm946_busy && !arm946_cycle_valid);
      end

      // All classification inputs are sampled at acceptance.
      multiply_kind = ARM9_MULTIPLY_DSP_SHORT;
      multiplier_operand_high = 24'hffffff;
      set_flags = !flags;
      qualified_result_dependency = !dependency;
      #1ps;
      if (cycle <= tdmi_total) begin
        assert (tdmi_active_multiply_kind == kind);
      end
      if (cycle <= arm946_total) begin
        assert (arm946_active_multiply_kind == kind);
      end
      @(posedge clk);
      #1ps;
      if (cycle == tdmi_total) begin
        assert (tdmi_operation_complete && !tdmi_busy);
      end else begin
        assert (!tdmi_operation_complete);
      end
      if (cycle == arm946_total) begin
        assert (arm946_operation_complete && !arm946_busy);
      end else begin
        assert (!arm946_operation_complete);
      end
    end
  endtask

  task automatic run_dsp_request(
    input arm9_multiply_kind_e kind,
    input logic dependency
  );
    logic [3:0] total;

    total = arm946_expected_cycles(kind, 1'b0, dependency);
    @(negedge clk);
    assert (tdmi_ready && arm946_ready);
    multiply_kind = kind;
    multiplier_operand_high = 24'h123456;
    set_flags = 1'b0;
    qualified_result_dependency = dependency;
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;
    assert (!tdmi_request_accepted && tdmi_request_error);
    assert (!tdmi_busy && !tdmi_cycle_valid && tdmi_ready);
    assert (arm946_request_accepted && !arm946_request_error);
    requests_checked++;

    for (logic [3:0] cycle = 4'd1; cycle <= total; cycle++) begin
      check_arm946_cycle(kind, 1'b0, dependency, dependency,
                         cycle, total);
      @(posedge clk);
      #1ps;
    end
    assert (!arm946_busy && arm946_operation_complete && arm946_ready);
  endtask

  initial begin
    reset = 1'b1;
    start = 1'b0;
    multiply_kind = ARM9_MULTIPLY_MUL;
    multiplier_operand_high = 24'b0;
    set_flags = 1'b0;
    qualified_result_dependency = 1'b0;
    cycles_checked = 0;
    requests_checked = 0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    reset = 1'b0;

    // REQ: ARM9TDMI-TIMING-MUL-001
    // REQ: ARM9TDMI-TIMING-MULL-001
    // REQ: ARM9TDMI-TIMING-MULTERM-001
    // REQ: ARM9TDMI-TIMING-MULTERM-002
    // REQ: ARM946ES-TIMING-MUL-001
    // REQ: ARM946ES-TIMING-MUL-002
    // REQ: ARM946ES-TIMING-MULS-001
    // REQ: ARM946ES-TIMING-MULL-001
    // REQ: ARM946ES-TIMING-MULL-002
    // REQ: ARM946ES-TIMING-MULLS-001
    for (int unsigned kind_index = 0; kind_index < 6; kind_index++) begin
      for (int unsigned early_class = 1; early_class <= 4;
           early_class++) begin
        for (int unsigned flags = 0; flags < 2; flags++) begin
          for (int unsigned dependency = 0; dependency < 2;
               dependency++) begin
            run_common_request(
              arm9_multiply_kind_e'(kind_index[2:0]),
              early_class[2:0], flags[0], dependency[0]
            );
          end
        end
      end
    end

    // REQ: ARM946ES-TIMING-SMULXY-001
    // REQ: ARM946ES-TIMING-SMULXY-002
    // REQ: ARM946ES-TIMING-SMULWX-001
    // REQ: ARM946ES-TIMING-SMULWX-002
    // REQ: ARM946ES-TIMING-SMLALXY-001
    // REQ: ARM946ES-TIMING-SMLALXY-002
    run_dsp_request(ARM9_MULTIPLY_DSP_SHORT, 1'b0);
    run_dsp_request(ARM9_MULTIPLY_DSP_SHORT, 1'b1);
    run_dsp_request(ARM9_MULTIPLY_DSP_LONG, 1'b0);
    run_dsp_request(ARM9_MULTIPLY_DSP_LONG, 1'b1);

    assert (requests_checked == 100);
    $display("PASS profile multiply sequences (%0d requests, %0d cycles)",
             requests_checked, cycles_checked);
    $finish;
  end
endmodule
