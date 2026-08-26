module swap_timing_tb;
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic clk;
  logic reset;
  logic start;
  logic [1:0] result_interlock_cycles;

  logic tdmi_ready;
  logic tdmi_request_accepted;
  logic tdmi_request_error;
  logic tdmi_busy;
  logic tdmi_cycle_valid;
  logic [2:0] tdmi_cycle_number;
  logic [2:0] tdmi_cycle_total;
  logic [1:0] tdmi_active_result_interlock_cycles;
  arm9_bus_cycle_e tdmi_instruction_cycle_type;
  arm9_bus_cycle_e tdmi_data_cycle_type;
  logic tdmi_instruction_order_documented;
  logic tdmi_data_order_documented;
  logic [2:0] tdmi_instruction_sequential_cycles;
  logic [2:0] tdmi_instruction_internal_cycles;
  logic [2:0] tdmi_data_nonsequential_cycles;
  logic [2:0] tdmi_data_internal_cycles;
  logic tdmi_swap_read_cycle;
  logic tdmi_swap_write_cycle;
  logic tdmi_data_lock;
  logic tdmi_operation_complete;

  logic arm946_ready;
  logic arm946_request_accepted;
  logic arm946_request_error;
  logic arm946_busy;
  logic arm946_cycle_valid;
  logic [2:0] arm946_cycle_number;
  logic [2:0] arm946_cycle_total;
  logic [1:0] arm946_active_result_interlock_cycles;
  arm9_bus_cycle_e arm946_instruction_cycle_type;
  arm9_bus_cycle_e arm946_data_cycle_type;
  logic arm946_instruction_order_documented;
  logic arm946_data_order_documented;
  logic [2:0] arm946_instruction_sequential_cycles;
  logic [2:0] arm946_instruction_internal_cycles;
  logic [2:0] arm946_data_nonsequential_cycles;
  logic [2:0] arm946_data_internal_cycles;
  logic arm946_swap_read_cycle;
  logic arm946_swap_write_cycle;
  logic arm946_data_lock;
  logic arm946_operation_complete;
  int unsigned cycles_checked;

  arm9_swap_timing #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .clk,
    .reset,
    .start,
    .result_interlock_cycles,
    .ready(tdmi_ready),
    .request_accepted(tdmi_request_accepted),
    .request_error(tdmi_request_error),
    .busy(tdmi_busy),
    .cycle_valid(tdmi_cycle_valid),
    .cycle_number(tdmi_cycle_number),
    .cycle_total(tdmi_cycle_total),
    .active_result_interlock_cycles(tdmi_active_result_interlock_cycles),
    .instruction_cycle_type(tdmi_instruction_cycle_type),
    .data_cycle_type(tdmi_data_cycle_type),
    .instruction_order_documented(tdmi_instruction_order_documented),
    .data_order_documented(tdmi_data_order_documented),
    .instruction_sequential_cycles(tdmi_instruction_sequential_cycles),
    .instruction_internal_cycles(tdmi_instruction_internal_cycles),
    .data_nonsequential_cycles(tdmi_data_nonsequential_cycles),
    .data_internal_cycles(tdmi_data_internal_cycles),
    .swap_read_cycle(tdmi_swap_read_cycle),
    .swap_write_cycle(tdmi_swap_write_cycle),
    .data_lock(tdmi_data_lock),
    .operation_complete(tdmi_operation_complete)
  );

  arm9_swap_timing #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .clk,
    .reset,
    .start,
    .result_interlock_cycles,
    .ready(arm946_ready),
    .request_accepted(arm946_request_accepted),
    .request_error(arm946_request_error),
    .busy(arm946_busy),
    .cycle_valid(arm946_cycle_valid),
    .cycle_number(arm946_cycle_number),
    .cycle_total(arm946_cycle_total),
    .active_result_interlock_cycles(arm946_active_result_interlock_cycles),
    .instruction_cycle_type(arm946_instruction_cycle_type),
    .data_cycle_type(arm946_data_cycle_type),
    .instruction_order_documented(arm946_instruction_order_documented),
    .data_order_documented(arm946_data_order_documented),
    .instruction_sequential_cycles(arm946_instruction_sequential_cycles),
    .instruction_internal_cycles(arm946_instruction_internal_cycles),
    .data_nonsequential_cycles(arm946_data_nonsequential_cycles),
    .data_internal_cycles(arm946_data_internal_cycles),
    .swap_read_cycle(arm946_swap_read_cycle),
    .swap_write_cycle(arm946_swap_write_cycle),
    .data_lock(arm946_data_lock),
    .operation_complete(arm946_operation_complete)
  );

  initial begin
    clk = 1'b0;
    forever #5ns clk = !clk;
  end

  task automatic check_tdmi_cycle(
    input logic [2:0] cycle,
    input logic [2:0] total,
    input logic [1:0] interlocks
  );
    assert (tdmi_busy && tdmi_cycle_valid);
    assert (tdmi_cycle_number == cycle);
    assert (tdmi_cycle_total == total);
    assert (tdmi_active_result_interlock_cycles == interlocks);
    assert (tdmi_instruction_sequential_cycles == 3'd1);
    assert (tdmi_instruction_internal_cycles == total - 3'd1);
    assert (tdmi_data_nonsequential_cycles == 3'd2);
    assert (tdmi_data_internal_cycles == total - 3'd2);
    assert (!tdmi_instruction_order_documented);
    assert (!tdmi_data_order_documented);
    assert (tdmi_instruction_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (tdmi_swap_read_cycle == (cycle == 1));
    assert (tdmi_swap_write_cycle == (cycle == 2));
    assert (tdmi_data_lock == (cycle <= 2));
    cycles_checked += 1;
  endtask

  task automatic check_arm946_cycle(
    input logic [2:0] cycle,
    input logic [2:0] total,
    input logic [1:0] interlocks
  );
    assert (arm946_busy && arm946_cycle_valid);
    assert (arm946_cycle_number == cycle);
    assert (arm946_cycle_total == total);
    assert (arm946_active_result_interlock_cycles == interlocks);
    assert (arm946_instruction_sequential_cycles == 3'd1);
    assert (arm946_instruction_internal_cycles == total - 3'd1);
    assert (arm946_data_nonsequential_cycles == 3'd2);
    assert (arm946_data_internal_cycles == total - 3'd2);
    assert (arm946_instruction_order_documented);
    assert (arm946_data_order_documented);
    assert (arm946_instruction_cycle_type ==
            ((cycle == total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                                ARM9_BUS_CYCLE_INTERNAL));
    assert (arm946_data_cycle_type ==
            ((cycle <= 2) ? ARM9_BUS_CYCLE_NONSEQUENTIAL :
                            ARM9_BUS_CYCLE_INTERNAL));
    assert (arm946_swap_read_cycle == (cycle == 1));
    assert (arm946_swap_write_cycle == (cycle == 2));
    assert (arm946_data_lock == (cycle <= 2));
    cycles_checked += 1;
  endtask

  task automatic run_shared_request(
    input logic [1:0] interlocks
  );
    logic [2:0] cycle;
    logic [2:0] total;

    total = 3'd2 + {1'b0, interlocks};
    @(negedge clk);
    result_interlock_cycles = interlocks;
    start = 1'b1;
    @(posedge clk);
    #1ns;
    assert (tdmi_request_accepted && !tdmi_request_error);
    assert (arm946_request_accepted && !arm946_request_error);
    for (cycle = 1; cycle <= total; cycle++) begin
      check_tdmi_cycle(cycle, total, interlocks);
      check_arm946_cycle(cycle, total, interlocks);
      if (cycle == 1) begin
        start = 1'b0;
      end
      @(posedge clk);
      #1ns;
    end
    assert (!tdmi_busy && tdmi_operation_complete && tdmi_ready);
    assert (!arm946_busy && arm946_operation_complete && arm946_ready);
  endtask

  task automatic run_arm946_two_interlock_request;
    logic [2:0] cycle;

    @(negedge clk);
    result_interlock_cycles = 2'd2;
    start = 1'b1;
    @(posedge clk);
    #1ns;
    assert (!tdmi_request_accepted && tdmi_request_error && !tdmi_busy);
    assert (arm946_request_accepted && !arm946_request_error);
    for (cycle = 3'd1; cycle <= 3'd4; cycle++) begin
      check_arm946_cycle(cycle, 3'd4, 2'd2);
      if (cycle == 1) begin
        start = 1'b0;
      end
      @(posedge clk);
      #1ns;
    end
    assert (!arm946_busy && arm946_operation_complete && arm946_ready);
  endtask

  initial begin
    reset = 1'b1;
    start = 1'b0;
    result_interlock_cycles = 2'd0;
    cycles_checked = 0;
    repeat (2) @(posedge clk);
    #1ns;
    reset = 1'b0;

    // REQ: ARM9TDMI-TIMING-SWP-001
    // REQ: ARM9TDMI-TIMING-SWP-002
    // REQ: ARM946ES-TIMING-SWP-001
    // REQ: ARM946ES-TIMING-SWP-002
    // REQ: ARM946ES-TIMING-SWP-003
    run_shared_request(2'd0);
    run_shared_request(2'd1);
    run_arm946_two_interlock_request();

    @(negedge clk);
    result_interlock_cycles = 2'd3;
    start = 1'b1;
    @(posedge clk);
    #1ns;
    assert (tdmi_request_error && !tdmi_request_accepted && !tdmi_busy);
    assert (arm946_request_error && !arm946_request_accepted && !arm946_busy);
    start = 1'b0;

    assert (cycles_checked == 14);
    $display("PASS profile SWP timing (%0d cycle observations)",
             cycles_checked);
    $finish;
  end
endmodule
