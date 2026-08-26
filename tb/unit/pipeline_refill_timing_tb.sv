module pipeline_refill_timing_tb;
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic clk;
  logic reset;
  logic start;
  logic branch_operation;
  logic exception_entry;

  logic tdmi_ready;
  logic tdmi_request_accepted;
  logic tdmi_request_error;
  logic tdmi_busy;
  logic tdmi_cycle_valid;
  logic [1:0] tdmi_cycle_number;
  logic tdmi_active_branch_operation;
  logic tdmi_active_exception_entry;
  arm9_bus_cycle_e tdmi_instruction_cycle_type;
  arm9_bus_cycle_e tdmi_data_cycle_type;
  logic tdmi_instruction_order_documented;
  logic [1:0] tdmi_instruction_sequential_cycles;
  logic [1:0] tdmi_instruction_nonsequential_cycles;
  logic [1:0] tdmi_data_internal_cycles;
  logic tdmi_operation_complete;

  logic arm946_ready;
  logic arm946_request_accepted;
  logic arm946_request_error;
  logic arm946_busy;
  logic arm946_cycle_valid;
  logic [1:0] arm946_cycle_number;
  logic arm946_active_branch_operation;
  logic arm946_active_exception_entry;
  arm9_bus_cycle_e arm946_instruction_cycle_type;
  arm9_bus_cycle_e arm946_data_cycle_type;
  logic arm946_instruction_order_documented;
  logic [1:0] arm946_instruction_sequential_cycles;
  logic [1:0] arm946_instruction_nonsequential_cycles;
  logic [1:0] arm946_data_internal_cycles;
  logic arm946_operation_complete;
  int unsigned cycles_checked;

  arm9_pipeline_refill_timing #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .clk,
    .reset,
    .start,
    .branch_operation,
    .exception_entry,
    .ready(tdmi_ready),
    .request_accepted(tdmi_request_accepted),
    .request_error(tdmi_request_error),
    .busy(tdmi_busy),
    .cycle_valid(tdmi_cycle_valid),
    .cycle_number(tdmi_cycle_number),
    .active_branch_operation(tdmi_active_branch_operation),
    .active_exception_entry(tdmi_active_exception_entry),
    .instruction_cycle_type(tdmi_instruction_cycle_type),
    .data_cycle_type(tdmi_data_cycle_type),
    .instruction_order_documented(tdmi_instruction_order_documented),
    .instruction_sequential_cycles(tdmi_instruction_sequential_cycles),
    .instruction_nonsequential_cycles(
      tdmi_instruction_nonsequential_cycles
    ),
    .data_internal_cycles(tdmi_data_internal_cycles),
    .operation_complete(tdmi_operation_complete)
  );

  arm9_pipeline_refill_timing #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .clk,
    .reset,
    .start,
    .branch_operation,
    .exception_entry,
    .ready(arm946_ready),
    .request_accepted(arm946_request_accepted),
    .request_error(arm946_request_error),
    .busy(arm946_busy),
    .cycle_valid(arm946_cycle_valid),
    .cycle_number(arm946_cycle_number),
    .active_branch_operation(arm946_active_branch_operation),
    .active_exception_entry(arm946_active_exception_entry),
    .instruction_cycle_type(arm946_instruction_cycle_type),
    .data_cycle_type(arm946_data_cycle_type),
    .instruction_order_documented(arm946_instruction_order_documented),
    .instruction_sequential_cycles(arm946_instruction_sequential_cycles),
    .instruction_nonsequential_cycles(
      arm946_instruction_nonsequential_cycles
    ),
    .data_internal_cycles(arm946_data_internal_cycles),
    .operation_complete(arm946_operation_complete)
  );

  initial begin
    clk = 1'b0;
    forever #5ns clk = !clk;
  end

  task automatic check_active_cycle(
    input logic is_branch,
    input int unsigned cycle
  );
    assert (tdmi_busy && tdmi_cycle_valid);
    assert (tdmi_cycle_number == cycle[1:0]);
    assert (tdmi_active_branch_operation == is_branch);
    assert (tdmi_active_exception_entry == !is_branch);
    assert (tdmi_instruction_sequential_cycles == 2'd2);
    assert (tdmi_instruction_nonsequential_cycles == 2'd1);
    assert (tdmi_data_internal_cycles == 2'd3);
    assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
    assert (!tdmi_instruction_order_documented);
    assert (tdmi_instruction_cycle_type ==
            ARM9_BUS_CYCLE_UNSPECIFIED);

    assert (arm946_busy && arm946_cycle_valid);
    assert (arm946_cycle_number == cycle[1:0]);
    assert (arm946_active_branch_operation == is_branch);
    assert (arm946_active_exception_entry == !is_branch);
    assert (arm946_instruction_sequential_cycles == 2'd2);
    assert (arm946_instruction_nonsequential_cycles == 2'd1);
    assert (arm946_data_internal_cycles == 2'd3);
    assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
    assert (arm946_instruction_order_documented);
    assert (arm946_instruction_cycle_type ==
            ((cycle == 1) ? ARM9_BUS_CYCLE_NONSEQUENTIAL :
                            ARM9_BUS_CYCLE_SEQUENTIAL));
    cycles_checked += 2;
  endtask

  task automatic run_request(input logic is_branch);
    @(negedge clk);
    assert (tdmi_ready && arm946_ready);
    branch_operation = is_branch;
    exception_entry = !is_branch;
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;
    assert (tdmi_request_accepted && arm946_request_accepted);
    assert (!tdmi_request_error && !arm946_request_error);

    for (int unsigned cycle = 1; cycle <= 3; cycle++) begin
      check_active_cycle(is_branch, cycle);
      @(posedge clk);
      #1ps;
      if (cycle == 3) begin
        assert (tdmi_operation_complete && !tdmi_busy);
        assert (arm946_operation_complete && !arm946_busy);
      end else begin
        assert (!tdmi_operation_complete && tdmi_busy);
        assert (!arm946_operation_complete && arm946_busy);
      end
    end
  endtask

  task automatic reject_request(
    input logic request_branch,
    input logic request_exception
  );
    @(negedge clk);
    branch_operation = request_branch;
    exception_entry = request_exception;
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;
    assert (tdmi_request_error && arm946_request_error);
    assert (!tdmi_request_accepted && !arm946_request_accepted);
    assert (!tdmi_busy && !arm946_busy);
  endtask

  initial begin
    reset = 1'b1;
    start = 1'b0;
    branch_operation = 1'b0;
    exception_entry = 1'b0;
    cycles_checked = 0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    reset = 1'b0;

    // REQ: ARM9TDMI-TIMING-BRANCH-001
    // REQ: ARM946ES-TIMING-BRANCH-001
    run_request(1'b1);

    // REQ: ARM9TDMI-TIMING-EXCEPTION-001
    // REQ: ARM946ES-TIMING-EXCEPTION-001
    run_request(1'b0);

    reject_request(1'b0, 1'b0);
    reject_request(1'b1, 1'b1);

    assert (cycles_checked == 12);
    $display("PASS profile branch/exception refill timing (%0d cycles)",
             cycles_checked);
    $finish;
  end
endmodule
