module saturating_timing_tb;
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic clk;
  logic reset;
  logic start;
  logic result_interlock;

  logic tdmi_ready;
  logic tdmi_request_accepted;
  logic tdmi_request_error;
  logic tdmi_busy;
  logic tdmi_cycle_valid;
  logic [1:0] tdmi_cycle_number;
  logic [1:0] tdmi_cycle_total;
  logic tdmi_active_result_interlock;
  arm9_bus_cycle_e tdmi_instruction_cycle_type;
  arm9_bus_cycle_e tdmi_data_cycle_type;
  logic tdmi_instruction_order_documented;
  logic [1:0] tdmi_instruction_sequential_cycles;
  logic [1:0] tdmi_instruction_internal_cycles;
  logic [1:0] tdmi_data_internal_cycles;
  logic tdmi_operation_complete;

  logic arm946_ready;
  logic arm946_request_accepted;
  logic arm946_request_error;
  logic arm946_busy;
  logic arm946_cycle_valid;
  logic [1:0] arm946_cycle_number;
  logic [1:0] arm946_cycle_total;
  logic arm946_active_result_interlock;
  arm9_bus_cycle_e arm946_instruction_cycle_type;
  arm9_bus_cycle_e arm946_data_cycle_type;
  logic arm946_instruction_order_documented;
  logic [1:0] arm946_instruction_sequential_cycles;
  logic [1:0] arm946_instruction_internal_cycles;
  logic [1:0] arm946_data_internal_cycles;
  logic arm946_operation_complete;
  int unsigned cycles_checked;

  arm9_saturating_timing #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .clk,
    .reset,
    .start,
    .result_interlock,
    .ready(tdmi_ready),
    .request_accepted(tdmi_request_accepted),
    .request_error(tdmi_request_error),
    .busy(tdmi_busy),
    .cycle_valid(tdmi_cycle_valid),
    .cycle_number(tdmi_cycle_number),
    .cycle_total(tdmi_cycle_total),
    .active_result_interlock(tdmi_active_result_interlock),
    .instruction_cycle_type(tdmi_instruction_cycle_type),
    .data_cycle_type(tdmi_data_cycle_type),
    .instruction_order_documented(tdmi_instruction_order_documented),
    .instruction_sequential_cycles(tdmi_instruction_sequential_cycles),
    .instruction_internal_cycles(tdmi_instruction_internal_cycles),
    .data_internal_cycles(tdmi_data_internal_cycles),
    .operation_complete(tdmi_operation_complete)
  );

  arm9_saturating_timing #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .clk,
    .reset,
    .start,
    .result_interlock,
    .ready(arm946_ready),
    .request_accepted(arm946_request_accepted),
    .request_error(arm946_request_error),
    .busy(arm946_busy),
    .cycle_valid(arm946_cycle_valid),
    .cycle_number(arm946_cycle_number),
    .cycle_total(arm946_cycle_total),
    .active_result_interlock(arm946_active_result_interlock),
    .instruction_cycle_type(arm946_instruction_cycle_type),
    .data_cycle_type(arm946_data_cycle_type),
    .instruction_order_documented(arm946_instruction_order_documented),
    .instruction_sequential_cycles(arm946_instruction_sequential_cycles),
    .instruction_internal_cycles(arm946_instruction_internal_cycles),
    .data_internal_cycles(arm946_data_internal_cycles),
    .operation_complete(arm946_operation_complete)
  );

  initial begin
    clk = 1'b0;
    forever #5ns clk = !clk;
  end

  task automatic check_tdmi_rejected;
    assert (!tdmi_request_accepted && tdmi_request_error);
    assert (!tdmi_busy && !tdmi_cycle_valid && tdmi_ready);
    assert ((tdmi_cycle_number == 2'd0) &&
            (tdmi_cycle_total == 2'd0));
    assert (!tdmi_active_result_interlock);
    assert (tdmi_instruction_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (!tdmi_instruction_order_documented);
    assert ((tdmi_instruction_sequential_cycles == 2'd0) &&
            (tdmi_instruction_internal_cycles == 2'd0) &&
            (tdmi_data_internal_cycles == 2'd0));
    assert (!tdmi_operation_complete);
  endtask

  task automatic run_request(input logic interlock);
    logic [1:0] total;

    total = interlock ? 2'd2 : 2'd1;
    @(negedge clk);
    assert (tdmi_ready && arm946_ready);
    result_interlock = interlock;
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;
    check_tdmi_rejected();
    assert (arm946_request_accepted && !arm946_request_error);

    for (logic [1:0] cycle = 2'd1; cycle <= total; cycle++) begin
      assert (arm946_busy && arm946_cycle_valid && !arm946_ready);
      assert ((arm946_cycle_number == cycle) &&
              (arm946_cycle_total == total));
      assert (arm946_active_result_interlock == interlock);
      assert (arm946_instruction_order_documented);
      assert (arm946_instruction_cycle_type ==
              ((cycle == total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                                  ARM9_BUS_CYCLE_INTERNAL));
      assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
      assert (arm946_instruction_sequential_cycles == 2'd1);
      assert (arm946_instruction_internal_cycles ==
              (interlock ? 2'd1 : 2'd0));
      assert (arm946_data_internal_cycles == total);
      cycles_checked++;

      // The qualifier is sampled only when the request is accepted.
      result_interlock = !interlock;
      #1ps;
      assert (arm946_active_result_interlock == interlock);
      @(posedge clk);
      #1ps;
    end
    assert (!arm946_busy && arm946_ready && arm946_operation_complete);
  endtask

  initial begin
    reset = 1'b1;
    start = 1'b0;
    result_interlock = 1'b0;
    cycles_checked = 0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    reset = 1'b0;

    // REQ: ARM946ES-TIMING-QADD-001
    run_request(1'b0);

    // REQ: ARM946ES-TIMING-QADD-002
    run_request(1'b1);

    assert (cycles_checked == 3);
    $display("PASS ARM946E-S saturating timing (%0d cycle observations)",
             cycles_checked);
    $finish;
  end
endmodule
