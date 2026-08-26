module doubleword_transfer_timing_tb;
  import arm9_profile_pkg::*;
  import arm9_timing_pkg::*;

  logic clk;
  logic reset;
  logic start;
  logic load_double;
  logic store_double;
  logic final_word_interlock;

  logic tdmi_ready;
  logic tdmi_request_accepted;
  logic tdmi_request_error;
  logic tdmi_busy;
  logic tdmi_cycle_valid;
  logic [4:0] tdmi_cycle_number;
  logic [4:0] tdmi_cycle_total;
  logic tdmi_active_load_double;
  logic tdmi_active_store_double;
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
  logic arm946_active_load_double;
  logic arm946_active_store_double;
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

  arm9_doubleword_transfer_timing #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .clk,
    .reset,
    .start,
    .load_double,
    .store_double,
    .final_word_interlock,
    .ready(tdmi_ready),
    .request_accepted(tdmi_request_accepted),
    .request_error(tdmi_request_error),
    .busy(tdmi_busy),
    .cycle_valid(tdmi_cycle_valid),
    .cycle_number(tdmi_cycle_number),
    .cycle_total(tdmi_cycle_total),
    .active_load_double(tdmi_active_load_double),
    .active_store_double(tdmi_active_store_double),
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

  arm9_doubleword_transfer_timing #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .clk,
    .reset,
    .start,
    .load_double,
    .store_double,
    .final_word_interlock,
    .ready(arm946_ready),
    .request_accepted(arm946_request_accepted),
    .request_error(arm946_request_error),
    .busy(arm946_busy),
    .cycle_valid(arm946_cycle_valid),
    .cycle_number(arm946_cycle_number),
    .cycle_total(arm946_cycle_total),
    .active_load_double(arm946_active_load_double),
    .active_store_double(arm946_active_store_double),
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

  task automatic check_cycle(
    input logic is_load,
    input logic interlock,
    input logic [4:0] cycle,
    input logic [4:0] total
  );
    assert (arm946_busy && arm946_cycle_valid);
    assert (arm946_cycle_number == cycle);
    assert (arm946_cycle_total == total);
    assert (arm946_active_load_double == is_load);
    assert (arm946_active_store_double == !is_load);
    assert (arm946_active_final_word_interlock == interlock);
    assert (arm946_instruction_order_documented);
    assert (arm946_data_order_documented);
    assert (arm946_instruction_sequential_cycles == 5'd1);
    assert (arm946_instruction_nonsequential_cycles == 5'd0);
    assert (arm946_instruction_internal_cycles == total - 5'd1);
    assert (arm946_data_sequential_cycles == 5'd1);
    assert (arm946_data_nonsequential_cycles == 5'd1);
    assert (arm946_data_internal_cycles == total - 5'd2);
    assert (arm946_instruction_cycle_type ==
            ((cycle == total) ? ARM9_BUS_CYCLE_SEQUENTIAL :
                                ARM9_BUS_CYCLE_INTERNAL));
    if (cycle == 5'd1) begin
      assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_NONSEQUENTIAL);
    end else if (cycle == 5'd2) begin
      assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_SEQUENTIAL);
    end else begin
      assert (arm946_data_cycle_type == ARM9_BUS_CYCLE_INTERNAL);
    end
    cycles_checked += 1;
  endtask

  task automatic check_tdmi_rejected;
    assert (!tdmi_request_accepted && tdmi_request_error);
    assert (!tdmi_busy && !tdmi_cycle_valid && tdmi_ready);
    assert ((tdmi_cycle_number == 5'd0) && (tdmi_cycle_total == 5'd0));
    assert (!tdmi_active_load_double && !tdmi_active_store_double);
    assert (!tdmi_active_final_word_interlock);
    assert (tdmi_instruction_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (tdmi_data_cycle_type == ARM9_BUS_CYCLE_UNSPECIFIED);
    assert (!tdmi_instruction_order_documented);
    assert (!tdmi_data_order_documented);
    assert ((tdmi_instruction_sequential_cycles == 5'd0) &&
            (tdmi_instruction_nonsequential_cycles == 5'd0) &&
            (tdmi_instruction_internal_cycles == 5'd0));
    assert ((tdmi_data_sequential_cycles == 5'd0) &&
            (tdmi_data_nonsequential_cycles == 5'd0) &&
            (tdmi_data_internal_cycles == 5'd0));
    assert (!tdmi_operation_complete);
  endtask

  task automatic run_request(
    input logic is_load,
    input logic interlock,
    input logic [4:0] total
  );
    logic [4:0] cycle;

    @(negedge clk);
    load_double = is_load;
    store_double = !is_load;
    final_word_interlock = interlock;
    start = 1'b1;
    @(posedge clk);
    #1ns;
    check_tdmi_rejected();
    assert (arm946_request_accepted && !arm946_request_error);
    for (cycle = 5'd1; cycle <= total; cycle++) begin
      check_cycle(is_load, interlock, cycle, total);
      if (cycle == 5'd1) begin
        start = 1'b0;
      end
      @(posedge clk);
      #1ns;
    end
    assert (!arm946_busy && arm946_operation_complete && arm946_ready);
  endtask

  task automatic expect_both_errors;
    @(negedge clk);
    start = 1'b1;
    @(posedge clk);
    #1ns;
    check_tdmi_rejected();
    assert (arm946_request_error && !arm946_request_accepted && !arm946_busy);
    start = 1'b0;
  endtask

  initial begin
    reset = 1'b1;
    start = 1'b0;
    load_double = 1'b0;
    store_double = 1'b0;
    final_word_interlock = 1'b0;
    cycles_checked = 0;
    repeat (2) @(posedge clk);
    #1ns;
    reset = 1'b0;

    // REQ: ARM946ES-TIMING-LDRD-001
    // REQ: ARM946ES-TIMING-LDRD-002
    // REQ: ARM946ES-TIMING-STRD-001
    run_request(1'b1, 1'b0, 5'd2);
    run_request(1'b1, 1'b1, 5'd3);
    run_request(1'b0, 1'b0, 5'd2);

    load_double = 1'b0;
    store_double = 1'b0;
    final_word_interlock = 1'b0;
    expect_both_errors();

    load_double = 1'b1;
    store_double = 1'b1;
    expect_both_errors();

    load_double = 1'b0;
    store_double = 1'b1;
    final_word_interlock = 1'b1;
    expect_both_errors();

    assert (cycles_checked == 7);
    $display("PASS ARM946E-S LDRD/STRD timing (%0d cycle observations)",
             cycles_checked);
    $finish;
  end
endmodule
