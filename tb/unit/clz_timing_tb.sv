module clz_timing_tb;
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic clk;
  logic reset;
  logic start;

  logic tdmi_ready;
  logic tdmi_request_accepted;
  logic tdmi_request_error;
  logic tdmi_busy;
  logic tdmi_cycle_valid;
  logic [2:0] tdmi_cycle_number;
  logic [2:0] tdmi_cycle_total;
  arm9_bus_cycle_e tdmi_instruction_cycle_type;
  arm9_bus_cycle_e tdmi_data_cycle_type;
  logic tdmi_instruction_order_documented;
  logic [2:0] tdmi_instruction_sequential_cycles;
  logic [2:0] tdmi_instruction_nonsequential_cycles;
  logic [2:0] tdmi_instruction_internal_cycles;
  logic [2:0] tdmi_data_internal_cycles;
  logic tdmi_operation_complete;

  logic arm946_ready;
  logic arm946_request_accepted;
  logic arm946_request_error;
  logic arm946_busy;
  logic arm946_cycle_valid;
  logic [2:0] arm946_cycle_number;
  logic [2:0] arm946_cycle_total;
  arm9_bus_cycle_e arm946_instruction_cycle_type;
  arm9_bus_cycle_e arm946_data_cycle_type;
  logic arm946_instruction_order_documented;
  logic [2:0] arm946_instruction_sequential_cycles;
  logic [2:0] arm946_instruction_nonsequential_cycles;
  logic [2:0] arm946_instruction_internal_cycles;
  logic [2:0] arm946_data_internal_cycles;
  logic arm946_operation_complete;
  int unsigned cycles_checked;

  arm9_clz_timing #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .clk,
    .reset,
    .start,
    .ready(tdmi_ready),
    .request_accepted(tdmi_request_accepted),
    .request_error(tdmi_request_error),
    .busy(tdmi_busy),
    .cycle_valid(tdmi_cycle_valid),
    .cycle_number(tdmi_cycle_number),
    .cycle_total(tdmi_cycle_total),
    .instruction_cycle_type(tdmi_instruction_cycle_type),
    .data_cycle_type(tdmi_data_cycle_type),
    .instruction_order_documented(tdmi_instruction_order_documented),
    .instruction_sequential_cycles(tdmi_instruction_sequential_cycles),
    .instruction_nonsequential_cycles(
      tdmi_instruction_nonsequential_cycles
    ),
    .instruction_internal_cycles(tdmi_instruction_internal_cycles),
    .data_internal_cycles(tdmi_data_internal_cycles),
    .operation_complete(tdmi_operation_complete)
  );

  arm9_clz_timing #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .clk,
    .reset,
    .start,
    .ready(arm946_ready),
    .request_accepted(arm946_request_accepted),
    .request_error(arm946_request_error),
    .busy(arm946_busy),
    .cycle_valid(arm946_cycle_valid),
    .cycle_number(arm946_cycle_number),
    .cycle_total(arm946_cycle_total),
    .instruction_cycle_type(arm946_instruction_cycle_type),
    .data_cycle_type(arm946_data_cycle_type),
    .instruction_order_documented(arm946_instruction_order_documented),
    .instruction_sequential_cycles(arm946_instruction_sequential_cycles),
    .instruction_nonsequential_cycles(
      arm946_instruction_nonsequential_cycles
    ),
    .instruction_internal_cycles(arm946_instruction_internal_cycles),
    .data_internal_cycles(arm946_data_internal_cycles),
    .operation_complete(arm946_operation_complete)
  );

  initial begin
    clk = 1'b0;
    forever #5ns clk = !clk;
  end

  task automatic check_idle;
    assert (tdmi_ready && !tdmi_busy && !tdmi_cycle_valid);
    assert ((tdmi_cycle_number == 3'd0) &&
            (tdmi_cycle_total == 3'd0));
    assert (!tdmi_instruction_order_documented);
    assert (tdmi_instruction_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert ((tdmi_instruction_sequential_cycles == 3'd0) &&
            (tdmi_instruction_nonsequential_cycles == 3'd0) &&
            (tdmi_instruction_internal_cycles == 3'd0) &&
            (tdmi_data_internal_cycles == 3'd0));

    assert (arm946_ready && !arm946_busy && !arm946_cycle_valid);
    assert ((arm946_cycle_number == 3'd0) &&
            (arm946_cycle_total == 3'd0));
    assert (!arm946_instruction_order_documented);
    assert (arm946_instruction_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert ((arm946_instruction_sequential_cycles == 3'd0) &&
            (arm946_instruction_nonsequential_cycles == 3'd0) &&
            (arm946_instruction_internal_cycles == 3'd0) &&
            (arm946_data_internal_cycles == 3'd0));
  endtask

  task automatic run_request;
    @(negedge clk);
    assert (tdmi_ready && arm946_ready);
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;

    assert (!tdmi_request_accepted && tdmi_request_error);
    assert (!tdmi_busy && !tdmi_cycle_valid && tdmi_ready);
    assert (!tdmi_operation_complete);

    // REQ: ARM946ES-TIMING-CLZ-001
    assert (arm946_request_accepted && !arm946_request_error);
    assert (arm946_busy && arm946_cycle_valid && !arm946_ready);
    assert ((arm946_cycle_number == 3'd1) &&
            (arm946_cycle_total == 3'd1));
    assert (arm946_instruction_order_documented);
    assert (arm946_instruction_cycle_type == ARM9_BUS_CYCLE_SEQUENTIAL);
    assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
    assert ((arm946_instruction_sequential_cycles == 3'd1) &&
            (arm946_instruction_nonsequential_cycles == 3'd0) &&
            (arm946_instruction_internal_cycles == 3'd0) &&
            (arm946_data_internal_cycles == 3'd1));
    assert (!arm946_operation_complete);
    cycles_checked++;

    @(posedge clk);
    #1ps;
    assert (!arm946_busy && arm946_ready && arm946_operation_complete);
    assert (!arm946_cycle_valid);
  endtask

  initial begin
    reset = 1'b1;
    start = 1'b0;
    cycles_checked = 0;
    repeat (2) @(posedge clk);
    #1ps;
    check_idle();
    @(negedge clk);
    reset = 1'b0;

    run_request();
    run_request();

    assert (cycles_checked == 2);
    $display("PASS ARM946E-S CLZ timing (%0d cycle observations)",
             cycles_checked);
    $finish;
  end
endmodule
