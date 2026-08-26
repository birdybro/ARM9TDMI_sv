module block_transfer_timing_tb;
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic clk;
  logic reset;
  logic start;
  logic load_multiple;
  logic store_multiple;
  logic [4:0] register_count;
  logic load_pc_destination;
  logic final_word_interlock;

  logic tdmi_ready;
  logic tdmi_request_accepted;
  logic tdmi_request_error;
  logic tdmi_busy;
  logic tdmi_cycle_valid;
  logic [4:0] tdmi_cycle_number;
  logic [4:0] tdmi_cycle_total;
  logic tdmi_active_load_multiple;
  logic tdmi_active_store_multiple;
  logic [4:0] tdmi_active_register_count;
  logic tdmi_active_load_pc_destination;
  logic tdmi_active_final_word_interlock;
  arm9_bus_cycle_e tdmi_instruction_cycle_type;
  arm9_bus_cycle_e tdmi_data_cycle_type;
  logic tdmi_instruction_order_documented;
  logic tdmi_data_order_documented;
  logic [4:0] tdmi_instruction_sequential_cycles;
  logic [4:0] tdmi_instruction_nonsequential_cycles;
  logic [4:0] tdmi_instruction_internal_cycles;
  logic [4:0] tdmi_data_sequential_cycles;
  logic [4:0] tdmi_data_nonsequential_cycles;
  logic [4:0] tdmi_data_internal_cycles;
  logic tdmi_operation_complete;

  logic arm946_ready;
  logic arm946_request_accepted;
  logic arm946_request_error;
  logic arm946_busy;
  logic arm946_cycle_valid;
  logic [4:0] arm946_cycle_number;
  logic [4:0] arm946_cycle_total;
  logic arm946_active_load_multiple;
  logic arm946_active_store_multiple;
  logic [4:0] arm946_active_register_count;
  logic arm946_active_load_pc_destination;
  logic arm946_active_final_word_interlock;
  arm9_bus_cycle_e arm946_instruction_cycle_type;
  arm9_bus_cycle_e arm946_data_cycle_type;
  logic arm946_instruction_order_documented;
  logic arm946_data_order_documented;
  logic [4:0] arm946_instruction_sequential_cycles;
  logic [4:0] arm946_instruction_nonsequential_cycles;
  logic [4:0] arm946_instruction_internal_cycles;
  logic [4:0] arm946_data_sequential_cycles;
  logic [4:0] arm946_data_nonsequential_cycles;
  logic [4:0] arm946_data_internal_cycles;
  logic arm946_operation_complete;
  int unsigned cycles_checked;

  arm9_block_transfer_timing #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .clk,
    .reset,
    .start,
    .load_multiple,
    .store_multiple,
    .register_count,
    .load_pc_destination,
    .final_word_interlock,
    .ready(tdmi_ready),
    .request_accepted(tdmi_request_accepted),
    .request_error(tdmi_request_error),
    .busy(tdmi_busy),
    .cycle_valid(tdmi_cycle_valid),
    .cycle_number(tdmi_cycle_number),
    .cycle_total(tdmi_cycle_total),
    .active_load_multiple(tdmi_active_load_multiple),
    .active_store_multiple(tdmi_active_store_multiple),
    .active_register_count(tdmi_active_register_count),
    .active_load_pc_destination(tdmi_active_load_pc_destination),
    .active_final_word_interlock(tdmi_active_final_word_interlock),
    .instruction_cycle_type(tdmi_instruction_cycle_type),
    .data_cycle_type(tdmi_data_cycle_type),
    .instruction_order_documented(tdmi_instruction_order_documented),
    .data_order_documented(tdmi_data_order_documented),
    .instruction_sequential_cycles(tdmi_instruction_sequential_cycles),
    .instruction_nonsequential_cycles(
      tdmi_instruction_nonsequential_cycles
    ),
    .instruction_internal_cycles(tdmi_instruction_internal_cycles),
    .data_sequential_cycles(tdmi_data_sequential_cycles),
    .data_nonsequential_cycles(tdmi_data_nonsequential_cycles),
    .data_internal_cycles(tdmi_data_internal_cycles),
    .operation_complete(tdmi_operation_complete)
  );

  arm9_block_transfer_timing #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .clk,
    .reset,
    .start,
    .load_multiple,
    .store_multiple,
    .register_count,
    .load_pc_destination,
    .final_word_interlock,
    .ready(arm946_ready),
    .request_accepted(arm946_request_accepted),
    .request_error(arm946_request_error),
    .busy(arm946_busy),
    .cycle_valid(arm946_cycle_valid),
    .cycle_number(arm946_cycle_number),
    .cycle_total(arm946_cycle_total),
    .active_load_multiple(arm946_active_load_multiple),
    .active_store_multiple(arm946_active_store_multiple),
    .active_register_count(arm946_active_register_count),
    .active_load_pc_destination(arm946_active_load_pc_destination),
    .active_final_word_interlock(arm946_active_final_word_interlock),
    .instruction_cycle_type(arm946_instruction_cycle_type),
    .data_cycle_type(arm946_data_cycle_type),
    .instruction_order_documented(arm946_instruction_order_documented),
    .data_order_documented(arm946_data_order_documented),
    .instruction_sequential_cycles(arm946_instruction_sequential_cycles),
    .instruction_nonsequential_cycles(
      arm946_instruction_nonsequential_cycles
    ),
    .instruction_internal_cycles(arm946_instruction_internal_cycles),
    .data_sequential_cycles(arm946_data_sequential_cycles),
    .data_nonsequential_cycles(arm946_data_nonsequential_cycles),
    .data_internal_cycles(arm946_data_internal_cycles),
    .operation_complete(arm946_operation_complete)
  );

  initial begin
    clk = 1'b0;
    forever #5ns clk = !clk;
  end

  function automatic int unsigned expected_total(
    input logic is_load,
    input int unsigned count,
    input logic loads_pc,
    input logic interlock
  );
    if (is_load && loads_pc) begin
      return count + 4;
    end
    if (is_load && interlock) begin
      return count + 1;
    end
    return (count == 1) ? 2 : count;
  endfunction

  function automatic arm9_bus_cycle_e expected_instruction_cycle(
    input int unsigned count,
    input logic loads_pc,
    input int unsigned cycle,
    input int unsigned total
  );
    if (loads_pc) begin
      if (cycle <= (count + 1)) begin
        return ARM9_BUS_CYCLE_INTERNAL;
      end
      if (cycle == (count + 2)) begin
        return ARM9_BUS_CYCLE_NONSEQUENTIAL;
      end
      return ARM9_BUS_CYCLE_SEQUENTIAL;
    end
    return (cycle == total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                              ARM9_BUS_CYCLE_INTERNAL;
  endfunction

  function automatic arm9_bus_cycle_e expected_data_cycle(
    input int unsigned count,
    input int unsigned cycle
  );
    if (cycle == 1) begin
      return ARM9_BUS_CYCLE_NONSEQUENTIAL;
    end
    if (cycle <= count) begin
      return ARM9_BUS_CYCLE_SEQUENTIAL;
    end
    return ARM9_BUS_CYCLE_INTERNAL;
  endfunction

  task automatic check_active_cycle(
    input logic is_load,
    input int unsigned count,
    input logic loads_pc,
    input logic interlock,
    input int unsigned cycle,
    input int unsigned total
  );
    logic [4:0] expected_instruction_sequential;
    logic [4:0] expected_instruction_nonsequential;
    logic [4:0] expected_instruction_internal;
    logic [4:0] expected_data_sequential;
    logic [4:0] expected_data_internal;

    expected_instruction_sequential = loads_pc ? 5'd2 : 5'd1;
    expected_instruction_nonsequential = loads_pc ? 5'd1 : 5'd0;
    expected_instruction_internal = 5'(total) -
      expected_instruction_sequential - expected_instruction_nonsequential;
    expected_data_sequential = (count > 1) ? 5'(count - 1) : 5'd0;
    expected_data_internal = 5'(total) - 5'd1 -
      expected_data_sequential;

    assert (tdmi_busy && tdmi_cycle_valid);
    assert (tdmi_cycle_number == cycle[4:0]);
    assert (tdmi_cycle_total == total[4:0]);
    assert (tdmi_active_load_multiple == is_load);
    assert (tdmi_active_store_multiple == !is_load);
    assert (tdmi_active_register_count == count[4:0]);
    assert (tdmi_active_load_pc_destination == (is_load && loads_pc));
    assert (tdmi_active_final_word_interlock == (is_load && interlock));
    assert (tdmi_instruction_sequential_cycles ==
            expected_instruction_sequential);
    assert (tdmi_instruction_nonsequential_cycles ==
            expected_instruction_nonsequential);
    assert (tdmi_instruction_internal_cycles ==
            expected_instruction_internal);
    if (is_load && !loads_pc && (count == 1)) begin
      assert (tdmi_data_sequential_cycles == 5'd1);
      assert (tdmi_data_nonsequential_cycles == 5'd0);
      assert (tdmi_data_internal_cycles == 5'd1);
    end else begin
      assert (tdmi_data_sequential_cycles == expected_data_sequential);
      assert (tdmi_data_nonsequential_cycles == 5'd1);
      assert (tdmi_data_internal_cycles == expected_data_internal);
    end
    assert (!tdmi_instruction_order_documented);
    assert (!tdmi_data_order_documented);
    assert (tdmi_instruction_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);

    assert (arm946_busy && arm946_cycle_valid);
    assert (arm946_cycle_number == cycle[4:0]);
    assert (arm946_cycle_total == total[4:0]);
    assert (arm946_active_load_multiple == is_load);
    assert (arm946_active_store_multiple == !is_load);
    assert (arm946_active_register_count == count[4:0]);
    assert (arm946_active_load_pc_destination == (is_load && loads_pc));
    assert (arm946_active_final_word_interlock == (is_load && interlock));
    assert (arm946_instruction_sequential_cycles ==
            expected_instruction_sequential);
    assert (arm946_instruction_nonsequential_cycles ==
            expected_instruction_nonsequential);
    assert (arm946_instruction_internal_cycles ==
            expected_instruction_internal);
    assert (arm946_data_sequential_cycles == expected_data_sequential);
    assert (arm946_data_nonsequential_cycles == 5'd1);
    assert (arm946_data_internal_cycles == expected_data_internal);
    assert (arm946_instruction_order_documented);
    assert (arm946_data_order_documented);
    assert (arm946_instruction_cycle_type == expected_instruction_cycle(
              count, loads_pc, cycle, total
            ));
    assert (arm946_data_cycle_type == expected_data_cycle(count, cycle));
    cycles_checked += 2;
  endtask

  task automatic run_request(
    input logic is_load,
    input int unsigned count,
    input logic loads_pc,
    input logic interlock
  );
    int unsigned total;

    total = expected_total(is_load, count, loads_pc, interlock);
    @(negedge clk);
    assert (tdmi_ready && arm946_ready);
    load_multiple = is_load;
    store_multiple = !is_load;
    register_count = count[4:0];
    load_pc_destination = loads_pc;
    final_word_interlock = interlock;
    start = 1'b1;
    @(posedge clk);
    #1ps;
    start = 1'b0;
    assert (tdmi_request_accepted && arm946_request_accepted);
    assert (!tdmi_request_error && !arm946_request_error);

    for (int unsigned cycle = 1; cycle <= total; cycle++) begin
      check_active_cycle(is_load, count, loads_pc, interlock,
                         cycle, total);
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
    input logic [4:0] count,
    input logic loads_pc,
    input logic interlock
  );
    @(negedge clk);
    load_multiple = request_load;
    store_multiple = request_store;
    register_count = count;
    load_pc_destination = loads_pc;
    final_word_interlock = interlock;
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
    load_multiple = 1'b0;
    store_multiple = 1'b0;
    register_count = 5'd0;
    load_pc_destination = 1'b0;
    final_word_interlock = 1'b0;
    cycles_checked = 0;
    repeat (2) @(posedge clk);
    @(negedge clk);
    reset = 1'b0;

    // REQ: ARM9TDMI-TIMING-LDM-001
    // REQ: ARM9TDMI-TIMING-LDM-002
    // REQ: ARM9TDMI-TIMING-LDM-003
    // REQ: ARM9TDMI-TIMING-LDM-004
    // REQ: ARM946ES-TIMING-LDM-001
    // REQ: ARM946ES-TIMING-LDM-002
    // REQ: ARM946ES-TIMING-LDM-003
    // REQ: ARM946ES-TIMING-LDM-004
    // REQ: ARM946ES-TIMING-LDM-005
    // REQ: ARM9TDMI-TIMING-STM-001
    // REQ: ARM9TDMI-TIMING-STM-002
    // REQ: ARM946ES-TIMING-STM-001
    // REQ: ARM946ES-TIMING-STM-002
    for (int unsigned count = 1; count <= 16; count++) begin
      run_request(1'b1, count, 1'b0, 1'b0);
      if (count > 1) begin
        run_request(1'b1, count, 1'b0, 1'b1);
      end
      run_request(1'b1, count, 1'b1, 1'b0);
      run_request(1'b0, count, 1'b0, 1'b0);
    end

    reject_request(1'b0, 1'b0, 5'd1, 1'b0, 1'b0);
    reject_request(1'b1, 1'b1, 5'd1, 1'b0, 1'b0);
    reject_request(1'b1, 1'b0, 5'd0, 1'b0, 1'b0);
    for (int unsigned count = 17; count <= 31; count++) begin
      reject_request(1'b1, 1'b0, count[4:0], 1'b0, 1'b0);
    end
    reject_request(1'b0, 1'b1, 5'd2, 1'b1, 1'b0);
    reject_request(1'b0, 1'b1, 5'd2, 1'b0, 1'b1);
    reject_request(1'b1, 1'b0, 5'd1, 1'b0, 1'b1);
    reject_request(1'b1, 1'b0, 5'd2, 1'b1, 1'b1);

    assert (cycles_checked == 1248);
    $display("PASS profile LDM/STM timing (%0d cycle observations)",
             cycles_checked);
    $finish;
  end
endmodule
