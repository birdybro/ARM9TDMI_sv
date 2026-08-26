module pld_timing_tb;
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic clk;
  logic reset;
  logic start;
  logic [31:0] prefetch_address;

  logic tdmi_ready;
  logic tdmi_request_accepted;
  logic tdmi_request_error;
  logic tdmi_busy;
  logic tdmi_cycle_valid;
  logic [1:0] tdmi_cycle_number;
  logic [1:0] tdmi_cycle_total;
  logic [31:0] tdmi_active_prefetch_address;
  logic tdmi_data_address_valid;
  logic tdmi_data_speculative;
  arm9_bus_cycle_e tdmi_instruction_cycle_type;
  arm9_bus_cycle_e tdmi_data_cycle_type;
  logic tdmi_instruction_order_documented;
  logic tdmi_data_order_documented;
  logic [1:0] tdmi_instruction_sequential_cycles;
  logic [1:0] tdmi_data_internal_cycles;
  logic tdmi_operation_complete;

  logic arm946_ready;
  logic arm946_request_accepted;
  logic arm946_request_error;
  logic arm946_busy;
  logic arm946_cycle_valid;
  logic [1:0] arm946_cycle_number;
  logic [1:0] arm946_cycle_total;
  logic [31:0] arm946_active_prefetch_address;
  logic arm946_data_address_valid;
  logic arm946_data_speculative;
  arm9_bus_cycle_e arm946_instruction_cycle_type;
  arm9_bus_cycle_e arm946_data_cycle_type;
  logic arm946_instruction_order_documented;
  logic arm946_data_order_documented;
  logic [1:0] arm946_instruction_sequential_cycles;
  logic [1:0] arm946_data_internal_cycles;
  logic arm946_operation_complete;
  int unsigned cycles_checked;

  arm9_pld_timing #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .clk,
    .reset,
    .start,
    .prefetch_address,
    .ready(tdmi_ready),
    .request_accepted(tdmi_request_accepted),
    .request_error(tdmi_request_error),
    .busy(tdmi_busy),
    .cycle_valid(tdmi_cycle_valid),
    .cycle_number(tdmi_cycle_number),
    .cycle_total(tdmi_cycle_total),
    .active_prefetch_address(tdmi_active_prefetch_address),
    .data_address_valid(tdmi_data_address_valid),
    .data_speculative(tdmi_data_speculative),
    .instruction_cycle_type(tdmi_instruction_cycle_type),
    .data_cycle_type(tdmi_data_cycle_type),
    .instruction_order_documented(tdmi_instruction_order_documented),
    .data_order_documented(tdmi_data_order_documented),
    .instruction_sequential_cycles(tdmi_instruction_sequential_cycles),
    .data_internal_cycles(tdmi_data_internal_cycles),
    .operation_complete(tdmi_operation_complete)
  );

  arm9_pld_timing #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .clk,
    .reset,
    .start,
    .prefetch_address,
    .ready(arm946_ready),
    .request_accepted(arm946_request_accepted),
    .request_error(arm946_request_error),
    .busy(arm946_busy),
    .cycle_valid(arm946_cycle_valid),
    .cycle_number(arm946_cycle_number),
    .cycle_total(arm946_cycle_total),
    .active_prefetch_address(arm946_active_prefetch_address),
    .data_address_valid(arm946_data_address_valid),
    .data_speculative(arm946_data_speculative),
    .instruction_cycle_type(arm946_instruction_cycle_type),
    .data_cycle_type(arm946_data_cycle_type),
    .instruction_order_documented(arm946_instruction_order_documented),
    .data_order_documented(arm946_data_order_documented),
    .instruction_sequential_cycles(arm946_instruction_sequential_cycles),
    .data_internal_cycles(arm946_data_internal_cycles),
    .operation_complete(arm946_operation_complete)
  );

  initial begin
    clk = 1'b0;
    forever #5ns clk = !clk;
  end

  task automatic check_idle;
    assert (tdmi_ready && !tdmi_busy && !tdmi_cycle_valid);
    assert (!tdmi_data_address_valid && !tdmi_data_speculative);
    assert (tdmi_active_prefetch_address == 32'b0);
    assert (tdmi_instruction_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (!tdmi_instruction_order_documented &&
            !tdmi_data_order_documented);
    assert ((tdmi_instruction_sequential_cycles == 2'd0) &&
            (tdmi_data_internal_cycles == 2'd0));

    assert (arm946_ready && !arm946_busy && !arm946_cycle_valid);
    assert (!arm946_data_address_valid && !arm946_data_speculative);
    assert (arm946_active_prefetch_address == 32'b0);
    assert (arm946_instruction_cycle_type ==
            ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (!arm946_instruction_order_documented &&
            !arm946_data_order_documented);
    assert ((arm946_instruction_sequential_cycles == 2'd0) &&
            (arm946_data_internal_cycles == 2'd0));
  endtask

  task automatic run_request(input logic [31:0] address);
    @(negedge clk);
    assert (tdmi_ready && arm946_ready);
    prefetch_address = address;
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;

    // ARM9TDMI is an ARMv4T profile and cannot start a PLD cycle.
    assert (!tdmi_request_accepted && tdmi_request_error);
    assert (!tdmi_busy && !tdmi_cycle_valid && tdmi_ready);
    assert ((tdmi_cycle_number == 2'd0) &&
            (tdmi_cycle_total == 2'd0));
    assert (!tdmi_data_address_valid && !tdmi_data_speculative);
    assert (!tdmi_operation_complete);

    // REQ: ARM946ES-TIMING-PLD-001
    assert (arm946_request_accepted && !arm946_request_error);
    assert (arm946_busy && arm946_cycle_valid && !arm946_ready);
    assert ((arm946_cycle_number == 2'd1) &&
            (arm946_cycle_total == 2'd1));
    assert (arm946_instruction_cycle_type == ARM9_BUS_CYCLE_SEQUENTIAL);
    assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
    assert (arm946_instruction_order_documented &&
            arm946_data_order_documented);
    assert ((arm946_instruction_sequential_cycles == 2'd1) &&
            (arm946_data_internal_cycles == 2'd1));
    assert (arm946_data_address_valid && arm946_data_speculative);
    assert (arm946_active_prefetch_address == address);
    assert (!arm946_operation_complete);
    cycles_checked++;

    // Inputs may move, but the active address remains stable for the cycle.
    prefetch_address = ~address;
    #1ps;
    assert (arm946_active_prefetch_address == address);
    @(posedge clk);
    #1ps;
    assert (!arm946_busy && arm946_ready && arm946_operation_complete);
    assert (!arm946_cycle_valid && !arm946_data_address_valid &&
            !arm946_data_speculative);
    assert (arm946_active_prefetch_address == 32'b0);
  endtask

  initial begin
    reset = 1'b1;
    start = 1'b0;
    prefetch_address = 32'b0;
    cycles_checked = 0;
    repeat (2) @(posedge clk);
    #1ps;
    check_idle();
    @(negedge clk);
    reset = 1'b0;

    run_request(32'h0000_0000);
    run_request(32'hffff_fffc);

    assert (cycles_checked == 2);
    $display("PASS ARM946E-S PLD timing (%0d cycle observations)",
             cycles_checked);
    $finish;
  end
endmodule
