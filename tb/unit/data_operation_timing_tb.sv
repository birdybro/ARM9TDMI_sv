module data_operation_timing_tb;
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic clk;
  logic reset;
  logic start;
  logic register_controlled_shift;
  logic pc_destination;

  logic tdmi_ready;
  logic tdmi_request_accepted;
  logic tdmi_busy;
  logic tdmi_cycle_valid;
  logic [2:0] tdmi_cycle_number;
  logic [2:0] tdmi_cycle_total;
  logic tdmi_active_register_controlled_shift;
  logic tdmi_active_pc_destination;
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
  logic arm946_busy;
  logic arm946_cycle_valid;
  logic [2:0] arm946_cycle_number;
  logic [2:0] arm946_cycle_total;
  logic arm946_active_register_controlled_shift;
  logic arm946_active_pc_destination;
  arm9_bus_cycle_e arm946_instruction_cycle_type;
  arm9_bus_cycle_e arm946_data_cycle_type;
  logic arm946_instruction_order_documented;
  logic [2:0] arm946_instruction_sequential_cycles;
  logic [2:0] arm946_instruction_nonsequential_cycles;
  logic [2:0] arm946_instruction_internal_cycles;
  logic [2:0] arm946_data_internal_cycles;
  logic arm946_operation_complete;
  int unsigned cycles_checked;

  arm9_data_operation_timing #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .clk,
    .reset,
    .start,
    .register_controlled_shift,
    .pc_destination,
    .ready(tdmi_ready),
    .request_accepted(tdmi_request_accepted),
    .busy(tdmi_busy),
    .cycle_valid(tdmi_cycle_valid),
    .cycle_number(tdmi_cycle_number),
    .cycle_total(tdmi_cycle_total),
    .active_register_controlled_shift(
      tdmi_active_register_controlled_shift
    ),
    .active_pc_destination(tdmi_active_pc_destination),
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

  arm9_data_operation_timing #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .clk,
    .reset,
    .start,
    .register_controlled_shift,
    .pc_destination,
    .ready(arm946_ready),
    .request_accepted(arm946_request_accepted),
    .busy(arm946_busy),
    .cycle_valid(arm946_cycle_valid),
    .cycle_number(arm946_cycle_number),
    .cycle_total(arm946_cycle_total),
    .active_register_controlled_shift(
      arm946_active_register_controlled_shift
    ),
    .active_pc_destination(arm946_active_pc_destination),
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

  function automatic arm9_bus_cycle_e arm946_expected_instruction_cycle(
    input logic shift_by_register,
    input logic writes_pc,
    input int unsigned cycle
  );
    int unsigned refill_cycle;

    refill_cycle = shift_by_register ? 2 : 1;
    if (shift_by_register && (cycle == 1)) begin
      return ARM9_BUS_CYCLE_INTERNAL;
    end
    if (writes_pc && (cycle == refill_cycle)) begin
      return ARM9_BUS_CYCLE_NONSEQUENTIAL;
    end
    return ARM9_BUS_CYCLE_SEQUENTIAL;
  endfunction

  task automatic check_active_cycle(
    input logic shift_by_register,
    input logic writes_pc,
    input int unsigned cycle,
    input int unsigned total
  );
    logic [2:0] expected_sequential;
    logic [2:0] expected_nonsequential;
    logic [2:0] expected_internal;

    expected_sequential = writes_pc ? 3'd2 : 3'd1;
    expected_nonsequential = writes_pc ? 3'd1 : 3'd0;
    expected_internal = shift_by_register ? 3'd1 : 3'd0;

    assert (tdmi_busy && tdmi_cycle_valid);
    assert (tdmi_cycle_number == cycle[2:0]);
    assert (tdmi_cycle_total == total[2:0]);
    assert (tdmi_active_register_controlled_shift ==
            shift_by_register);
    assert (tdmi_active_pc_destination == writes_pc);
    assert (tdmi_instruction_sequential_cycles == expected_sequential);
    assert (tdmi_instruction_nonsequential_cycles ==
            expected_nonsequential);
    assert (tdmi_instruction_internal_cycles == expected_internal);
    assert (tdmi_data_internal_cycles == total[2:0]);
    assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
    if (total == 1) begin
      assert (tdmi_instruction_order_documented);
      assert (tdmi_instruction_cycle_type ==
              ARM9_BUS_CYCLE_SEQUENTIAL);
    end else begin
      assert (!tdmi_instruction_order_documented);
      assert (tdmi_instruction_cycle_type ==
              ARM9_BUS_CYCLE_UNSPECIFIED);
    end

    assert (arm946_busy && arm946_cycle_valid);
    assert (arm946_cycle_number == cycle[2:0]);
    assert (arm946_cycle_total == total[2:0]);
    assert (arm946_active_register_controlled_shift ==
            shift_by_register);
    assert (arm946_active_pc_destination == writes_pc);
    assert (arm946_instruction_sequential_cycles == expected_sequential);
    assert (arm946_instruction_nonsequential_cycles ==
            expected_nonsequential);
    assert (arm946_instruction_internal_cycles == expected_internal);
    assert (arm946_data_internal_cycles == total[2:0]);
    assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
    assert (arm946_instruction_order_documented);
    assert (arm946_instruction_cycle_type ==
            arm946_expected_instruction_cycle(
              shift_by_register, writes_pc, cycle
            ));
    cycles_checked += 2;
  endtask

  task automatic run_class(
    input logic shift_by_register,
    input logic writes_pc,
    input int unsigned total
  );
    @(negedge clk);
    assert (tdmi_ready && arm946_ready);
    register_controlled_shift = shift_by_register;
    pc_destination = writes_pc;
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;
    assert (tdmi_request_accepted && arm946_request_accepted);

    for (int unsigned cycle = 1; cycle <= total; cycle++) begin
      check_active_cycle(shift_by_register, writes_pc, cycle, total);
      @(posedge clk);
      #1ps;
      if (cycle == total) begin
        assert (tdmi_operation_complete && !tdmi_busy);
        assert (arm946_operation_complete && !arm946_busy);
      end else begin
        assert (!tdmi_operation_complete && tdmi_busy);
        assert (!arm946_operation_complete && arm946_busy);
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    start = 1'b0;
    register_controlled_shift = 1'b0;
    pc_destination = 1'b0;
    cycles_checked = 0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    reset = 1'b0;

    // REQ: ARM9TDMI-TIMING-DP-001
    // REQ: ARM946ES-TIMING-DP-001
    run_class(1'b0, 1'b0, 1);

    // REQ: ARM9TDMI-TIMING-DP-002
    // REQ: ARM946ES-TIMING-DP-002
    run_class(1'b1, 1'b0, 2);

    // REQ: ARM9TDMI-TIMING-DP-003
    // REQ: ARM946ES-TIMING-DP-003
    run_class(1'b0, 1'b1, 3);

    // REQ: ARM9TDMI-TIMING-DP-004
    // REQ: ARM946ES-TIMING-DP-004
    run_class(1'b1, 1'b1, 4);

    assert (cycles_checked == 20);
    $display("PASS profile data-operation timing (%0d cycle observations)",
             cycles_checked);
    $finish;
  end
endmodule
