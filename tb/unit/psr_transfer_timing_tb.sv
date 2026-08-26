module psr_transfer_timing_tb;
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic clk;
  logic reset;
  logic start;
  logic mrs_operation;
  logic msr_operation;
  logic msr_flags_only;

  logic tdmi_ready;
  logic tdmi_request_accepted;
  logic tdmi_request_error;
  logic tdmi_busy;
  logic tdmi_cycle_valid;
  logic [1:0] tdmi_cycle_number;
  logic [1:0] tdmi_cycle_total;
  logic tdmi_active_mrs_operation;
  logic tdmi_active_msr_operation;
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
  logic arm946_active_mrs_operation;
  logic arm946_active_msr_operation;
  arm9_bus_cycle_e arm946_instruction_cycle_type;
  arm9_bus_cycle_e arm946_data_cycle_type;
  logic arm946_instruction_order_documented;
  logic [1:0] arm946_instruction_sequential_cycles;
  logic [1:0] arm946_instruction_internal_cycles;
  logic [1:0] arm946_data_internal_cycles;
  logic arm946_operation_complete;
  int unsigned cycles_checked;

  arm9_psr_transfer_timing #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .clk,
    .reset,
    .start,
    .mrs_operation,
    .msr_operation,
    .msr_flags_only,
    .ready(tdmi_ready),
    .request_accepted(tdmi_request_accepted),
    .request_error(tdmi_request_error),
    .busy(tdmi_busy),
    .cycle_valid(tdmi_cycle_valid),
    .cycle_number(tdmi_cycle_number),
    .cycle_total(tdmi_cycle_total),
    .active_mrs_operation(tdmi_active_mrs_operation),
    .active_msr_operation(tdmi_active_msr_operation),
    .instruction_cycle_type(tdmi_instruction_cycle_type),
    .data_cycle_type(tdmi_data_cycle_type),
    .instruction_order_documented(tdmi_instruction_order_documented),
    .instruction_sequential_cycles(tdmi_instruction_sequential_cycles),
    .instruction_internal_cycles(tdmi_instruction_internal_cycles),
    .data_internal_cycles(tdmi_data_internal_cycles),
    .operation_complete(tdmi_operation_complete)
  );

  arm9_psr_transfer_timing #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .clk,
    .reset,
    .start,
    .mrs_operation,
    .msr_operation,
    .msr_flags_only,
    .ready(arm946_ready),
    .request_accepted(arm946_request_accepted),
    .request_error(arm946_request_error),
    .busy(arm946_busy),
    .cycle_valid(arm946_cycle_valid),
    .cycle_number(arm946_cycle_number),
    .cycle_total(arm946_cycle_total),
    .active_mrs_operation(arm946_active_mrs_operation),
    .active_msr_operation(arm946_active_msr_operation),
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

  task automatic check_active_cycle(
    input int unsigned cycle,
    input int unsigned tdmi_total,
    input int unsigned arm946_total,
    input logic expected_mrs
  );
    if (cycle <= tdmi_total) begin
      assert (tdmi_busy && tdmi_cycle_valid);
      assert (tdmi_cycle_number == cycle[1:0]);
      assert (tdmi_cycle_total == tdmi_total[1:0]);
      assert (tdmi_active_mrs_operation == expected_mrs);
      assert (tdmi_active_msr_operation == !expected_mrs);
      assert (tdmi_instruction_sequential_cycles == 2'd1);
      assert (tdmi_instruction_internal_cycles == 2'(tdmi_total - 1));
      assert (tdmi_data_internal_cycles == tdmi_total[1:0]);
      assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
      if (tdmi_total == 1) begin
        assert (tdmi_instruction_order_documented);
        assert (tdmi_instruction_cycle_type ==
                ARM9_BUS_CYCLE_SEQUENTIAL);
      end else begin
        assert (!tdmi_instruction_order_documented);
        assert (tdmi_instruction_cycle_type ==
                ARM9_BUS_CYCLE_UNSPECIFIED);
      end
      cycles_checked++;
    end else begin
      assert (!tdmi_busy && !tdmi_cycle_valid);
    end

    if (cycle <= arm946_total) begin
      assert (arm946_busy && arm946_cycle_valid);
      assert (arm946_cycle_number == cycle[1:0]);
      assert (arm946_cycle_total == arm946_total[1:0]);
      assert (arm946_active_mrs_operation == expected_mrs);
      assert (arm946_active_msr_operation == !expected_mrs);
      assert (arm946_instruction_sequential_cycles == 2'd1);
      assert (arm946_instruction_internal_cycles == 2'(arm946_total - 1));
      assert (arm946_data_internal_cycles == arm946_total[1:0]);
      assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
      assert (arm946_instruction_order_documented);
      assert (arm946_instruction_cycle_type ==
              ((cycle == arm946_total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                                        ARM9_BUS_CYCLE_INTERNAL));
      cycles_checked++;
    end else begin
      assert (!arm946_busy && !arm946_cycle_valid);
    end
  endtask

  task automatic run_request(
    input logic request_mrs,
    input logic flags_only,
    input int unsigned tdmi_total,
    input int unsigned arm946_total
  );
    int unsigned maximum_cycles;

    @(negedge clk);
    assert (tdmi_ready && arm946_ready);
    mrs_operation = request_mrs;
    msr_operation = !request_mrs;
    msr_flags_only = flags_only;
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;
    assert (tdmi_request_accepted && arm946_request_accepted);
    assert (!tdmi_request_error && !arm946_request_error);

    maximum_cycles = (tdmi_total > arm946_total) ? tdmi_total :
                                                   arm946_total;
    for (int unsigned cycle = 1; cycle <= maximum_cycles; cycle++) begin
      check_active_cycle(cycle, tdmi_total, arm946_total, request_mrs);
      @(posedge clk);
      #1ps;
      if (cycle == tdmi_total) begin
        assert (tdmi_operation_complete && !tdmi_busy);
      end else if (cycle < tdmi_total) begin
        assert (!tdmi_operation_complete && tdmi_busy);
      end else begin
        assert (!tdmi_operation_complete && !tdmi_busy);
      end
      if (cycle == arm946_total) begin
        assert (arm946_operation_complete && !arm946_busy);
      end else if (cycle < arm946_total) begin
        assert (!arm946_operation_complete && arm946_busy);
      end else begin
        assert (!arm946_operation_complete && !arm946_busy);
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    start = 1'b0;
    mrs_operation = 1'b0;
    msr_operation = 1'b0;
    msr_flags_only = 1'b0;
    cycles_checked = 0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    reset = 1'b0;

    // REQ: ARM9TDMI-TIMING-MRS-001
    // REQ: ARM946ES-TIMING-MRS-001
    run_request(1'b1, 1'b0, 1, 2);

    // REQ: ARM9TDMI-TIMING-MSR-001
    // REQ: ARM946ES-TIMING-MSR-001
    run_request(1'b0, 1'b1, 1, 1);

    // REQ: ARM9TDMI-TIMING-MSR-002
    // REQ: ARM946ES-TIMING-MSR-002
    run_request(1'b0, 1'b0, 3, 3);

    // Malformed requests are rejected without entering a timing sequence.
    @(negedge clk);
    mrs_operation = 1'b1;
    msr_operation = 1'b1;
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;
    assert (tdmi_request_error && arm946_request_error);
    assert (!tdmi_request_accepted && !arm946_request_accepted);
    assert (!tdmi_busy && !arm946_busy);

    assert (cycles_checked == 11);
    $display("PASS profile-specific MRS/MSR timing (%0d cycle observations)",
             cycles_checked);
    $finish;
  end
endmodule
