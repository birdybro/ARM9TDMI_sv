module single_transfer_timing_tb;
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic clk;
  logic reset;
  logic start;
  logic load_operation;
  logic store_operation;
  arm9_load_timing_class_e load_timing_class;

  logic tdmi_ready;
  logic tdmi_request_accepted;
  logic tdmi_request_error;
  logic tdmi_busy;
  logic tdmi_cycle_valid;
  logic [2:0] tdmi_cycle_number;
  logic [2:0] tdmi_cycle_total;
  logic tdmi_active_load_operation;
  logic tdmi_active_store_operation;
  arm9_load_timing_class_e tdmi_active_load_timing_class;
  arm9_bus_cycle_e tdmi_instruction_cycle_type;
  arm9_bus_cycle_e tdmi_data_cycle_type;
  logic tdmi_instruction_order_documented;
  logic tdmi_data_order_documented;
  logic [2:0] tdmi_instruction_sequential_cycles;
  logic [2:0] tdmi_instruction_nonsequential_cycles;
  logic [2:0] tdmi_instruction_internal_cycles;
  logic [2:0] tdmi_data_nonsequential_cycles;
  logic [2:0] tdmi_data_internal_cycles;
  logic tdmi_operation_complete;

  logic arm946_ready;
  logic arm946_request_accepted;
  logic arm946_request_error;
  logic arm946_busy;
  logic arm946_cycle_valid;
  logic [2:0] arm946_cycle_number;
  logic [2:0] arm946_cycle_total;
  logic arm946_active_load_operation;
  logic arm946_active_store_operation;
  arm9_load_timing_class_e arm946_active_load_timing_class;
  arm9_bus_cycle_e arm946_instruction_cycle_type;
  arm9_bus_cycle_e arm946_data_cycle_type;
  logic arm946_instruction_order_documented;
  logic arm946_data_order_documented;
  logic [2:0] arm946_instruction_sequential_cycles;
  logic [2:0] arm946_instruction_nonsequential_cycles;
  logic [2:0] arm946_instruction_internal_cycles;
  logic [2:0] arm946_data_nonsequential_cycles;
  logic [2:0] arm946_data_internal_cycles;
  logic arm946_operation_complete;
  int unsigned cycles_checked;

  arm9_single_transfer_timing #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .clk,
    .reset,
    .start,
    .load_operation,
    .store_operation,
    .load_timing_class,
    .ready(tdmi_ready),
    .request_accepted(tdmi_request_accepted),
    .request_error(tdmi_request_error),
    .busy(tdmi_busy),
    .cycle_valid(tdmi_cycle_valid),
    .cycle_number(tdmi_cycle_number),
    .cycle_total(tdmi_cycle_total),
    .active_load_operation(tdmi_active_load_operation),
    .active_store_operation(tdmi_active_store_operation),
    .active_load_timing_class(tdmi_active_load_timing_class),
    .instruction_cycle_type(tdmi_instruction_cycle_type),
    .data_cycle_type(tdmi_data_cycle_type),
    .instruction_order_documented(tdmi_instruction_order_documented),
    .data_order_documented(tdmi_data_order_documented),
    .instruction_sequential_cycles(tdmi_instruction_sequential_cycles),
    .instruction_nonsequential_cycles(
      tdmi_instruction_nonsequential_cycles
    ),
    .instruction_internal_cycles(tdmi_instruction_internal_cycles),
    .data_nonsequential_cycles(tdmi_data_nonsequential_cycles),
    .data_internal_cycles(tdmi_data_internal_cycles),
    .operation_complete(tdmi_operation_complete)
  );

  arm9_single_transfer_timing #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .clk,
    .reset,
    .start,
    .load_operation,
    .store_operation,
    .load_timing_class,
    .ready(arm946_ready),
    .request_accepted(arm946_request_accepted),
    .request_error(arm946_request_error),
    .busy(arm946_busy),
    .cycle_valid(arm946_cycle_valid),
    .cycle_number(arm946_cycle_number),
    .cycle_total(arm946_cycle_total),
    .active_load_operation(arm946_active_load_operation),
    .active_store_operation(arm946_active_store_operation),
    .active_load_timing_class(arm946_active_load_timing_class),
    .instruction_cycle_type(arm946_instruction_cycle_type),
    .data_cycle_type(arm946_data_cycle_type),
    .instruction_order_documented(arm946_instruction_order_documented),
    .data_order_documented(arm946_data_order_documented),
    .instruction_sequential_cycles(arm946_instruction_sequential_cycles),
    .instruction_nonsequential_cycles(
      arm946_instruction_nonsequential_cycles
    ),
    .instruction_internal_cycles(arm946_instruction_internal_cycles),
    .data_nonsequential_cycles(arm946_data_nonsequential_cycles),
    .data_internal_cycles(arm946_data_internal_cycles),
    .operation_complete(arm946_operation_complete)
  );

  initial begin
    clk = 1'b0;
    forever #5ns clk = !clk;
  end

  function automatic arm9_bus_cycle_e expected_instruction_cycle(
    input arm9_load_timing_class_e timing_class,
    input logic is_store,
    input int unsigned cycle,
    input int unsigned total
  );
    if (is_store || (timing_class == ARM9_LOAD_TIMING_NORMAL)) begin
      return ARM9_BUS_CYCLE_SEQUENTIAL;
    end
    if (timing_class == ARM9_LOAD_TIMING_PC_DESTINATION) begin
      if (cycle <= 2) begin
        return ARM9_BUS_CYCLE_INTERNAL;
      end
      if (cycle == 3) begin
        return ARM9_BUS_CYCLE_NONSEQUENTIAL;
      end
      return ARM9_BUS_CYCLE_SEQUENTIAL;
    end
    return (cycle == total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                              ARM9_BUS_CYCLE_INTERNAL;
  endfunction

  task automatic check_active_cycle(
    input logic is_load,
    input arm9_load_timing_class_e timing_class,
    input int unsigned cycle,
    input int unsigned total,
    input logic [2:0] expected_instruction_sequential,
    input logic [2:0] expected_instruction_nonsequential,
    input logic [2:0] expected_instruction_internal,
    input logic [2:0] expected_data_internal
  );
    assert (tdmi_busy && tdmi_cycle_valid);
    assert (tdmi_cycle_number == cycle[2:0]);
    assert (tdmi_cycle_total == total[2:0]);
    assert (tdmi_active_load_operation == is_load);
    assert (tdmi_active_store_operation == !is_load);
    assert (tdmi_active_load_timing_class == timing_class);
    assert (tdmi_instruction_sequential_cycles ==
            expected_instruction_sequential);
    assert (tdmi_instruction_nonsequential_cycles ==
            expected_instruction_nonsequential);
    assert (tdmi_instruction_internal_cycles ==
            expected_instruction_internal);
    assert (tdmi_data_nonsequential_cycles == 3'd1);
    assert (tdmi_data_internal_cycles == expected_data_internal);
    if (total == 1) begin
      assert (tdmi_instruction_order_documented);
      assert (tdmi_data_order_documented);
      assert (tdmi_instruction_cycle_type ==
              ARM9_BUS_CYCLE_SEQUENTIAL);
      assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_NONSEQUENTIAL);
    end else begin
      assert (!tdmi_instruction_order_documented);
      assert (!tdmi_data_order_documented);
      assert (tdmi_instruction_cycle_type ==
              ARM9_BUS_CYCLE_UNSPECIFIED);
      assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    end

    assert (arm946_busy && arm946_cycle_valid);
    assert (arm946_cycle_number == cycle[2:0]);
    assert (arm946_cycle_total == total[2:0]);
    assert (arm946_active_load_operation == is_load);
    assert (arm946_active_store_operation == !is_load);
    assert (arm946_active_load_timing_class == timing_class);
    assert (arm946_instruction_sequential_cycles ==
            expected_instruction_sequential);
    assert (arm946_instruction_nonsequential_cycles ==
            expected_instruction_nonsequential);
    assert (arm946_instruction_internal_cycles ==
            expected_instruction_internal);
    assert (arm946_data_nonsequential_cycles == 3'd1);
    assert (arm946_data_internal_cycles == expected_data_internal);
    assert (arm946_instruction_order_documented);
    assert (arm946_data_order_documented);
    assert (arm946_instruction_cycle_type == expected_instruction_cycle(
              timing_class, !is_load, cycle, total
            ));
    assert (arm946_data_cycle_type ==
            ((cycle == 1) ? ARM9_BUS_CYCLE_NONSEQUENTIAL :
                            ARM9_BUS_CYCLE_INTERNAL));
    cycles_checked += 2;
  endtask

  task automatic run_request(
    input logic is_load,
    input arm9_load_timing_class_e timing_class,
    input int unsigned total,
    input logic [2:0] expected_instruction_sequential,
    input logic [2:0] expected_instruction_nonsequential,
    input logic [2:0] expected_instruction_internal,
    input logic [2:0] expected_data_internal
  );
    @(negedge clk);
    assert (tdmi_ready && arm946_ready);
    load_operation = is_load;
    store_operation = !is_load;
    load_timing_class = timing_class;
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;
    assert (tdmi_request_accepted && arm946_request_accepted);
    assert (!tdmi_request_error && !arm946_request_error);

    for (int unsigned cycle = 1; cycle <= total; cycle++) begin
      check_active_cycle(
        is_load, timing_class, cycle, total,
        expected_instruction_sequential,
        expected_instruction_nonsequential,
        expected_instruction_internal,
        expected_data_internal
      );
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

  task automatic reject_request(
    input logic request_load,
    input logic request_store,
    input arm9_load_timing_class_e timing_class
  );
    @(negedge clk);
    load_operation = request_load;
    store_operation = request_store;
    load_timing_class = timing_class;
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
    load_operation = 1'b0;
    store_operation = 1'b0;
    load_timing_class = ARM9_LOAD_TIMING_NORMAL;
    cycles_checked = 0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    reset = 1'b0;

    // REQ: ARM9TDMI-TIMING-LDR-001
    // REQ: ARM946ES-TIMING-LDR-001
    run_request(1'b1, ARM9_LOAD_TIMING_NORMAL, 1, 3'd1, 3'd0,
                3'd0, 3'd0);

    // REQ: ARM9TDMI-TIMING-LDR-002
    // REQ: ARM946ES-TIMING-LDR-002
    run_request(1'b1, ARM9_LOAD_TIMING_WORD_INTERLOCK, 2, 3'd1,
                3'd0, 3'd1, 3'd1);

    // REQ: ARM9TDMI-TIMING-LDR-003
    // REQ: ARM946ES-TIMING-LDR-003
    run_request(1'b1, ARM9_LOAD_TIMING_ROTATE_INTERLOCK, 3, 3'd1,
                3'd0, 3'd2, 3'd2);

    // REQ: ARM9TDMI-TIMING-LDR-004
    // REQ: ARM946ES-TIMING-LDR-004
    run_request(1'b1, ARM9_LOAD_TIMING_PC_DESTINATION, 5, 3'd2,
                3'd1, 3'd2, 3'd4);

    // REQ: ARM9TDMI-TIMING-STR-001
    // REQ: ARM946ES-TIMING-STR-001
    run_request(1'b0, ARM9_LOAD_TIMING_NORMAL, 1, 3'd1, 3'd0,
                3'd0, 3'd0);

    reject_request(1'b0, 1'b0, ARM9_LOAD_TIMING_NORMAL);
    reject_request(1'b1, 1'b1, ARM9_LOAD_TIMING_NORMAL);
    reject_request(1'b0, 1'b1, ARM9_LOAD_TIMING_WORD_INTERLOCK);

    assert (cycles_checked == 24);
    $display("PASS profile LDR/STR timing (%0d cycle observations)",
             cycles_checked);
    $finish;
  end
endmodule
