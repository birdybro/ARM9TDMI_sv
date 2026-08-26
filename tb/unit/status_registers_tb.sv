module status_registers_tb;
  import arm9_profile_pkg::*;
  import arm9_arch_pkg::*;
  import arm9_psr_pkg::*;

  logic       clk;
  logic       reset;
  logic       cpsr_write_enable;
  logic [31:0] cpsr_write_data;
  logic [31:0] cpsr_write_mask;
  logic [31:0] tdmi_cpsr_value;
  logic [31:0] arm946_cpsr_value;
  arm9_mode_e tdmi_current_mode;
  arm9_mode_e arm946_current_mode;
  arm9_mode_e spsr_read_mode;
  logic       tdmi_spsr_read_valid;
  logic       arm946_spsr_read_valid;
  logic [31:0] tdmi_spsr_read_value;
  logic [31:0] arm946_spsr_read_value;
  logic       spsr_write_enable;
  arm9_mode_e spsr_write_mode;
  logic [31:0] spsr_write_data;
  logic [31:0] spsr_write_mask;

  arm9_status_registers #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .cpsr_value(tdmi_cpsr_value),
    .current_mode(tdmi_current_mode),
    .spsr_read_valid(tdmi_spsr_read_valid),
    .spsr_read_value(tdmi_spsr_read_value),
    .*
  );

  arm9_status_registers #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .cpsr_value(arm946_cpsr_value),
    .current_mode(arm946_current_mode),
    .spsr_read_valid(arm946_spsr_read_valid),
    .spsr_read_value(arm946_spsr_read_value),
    .*
  );

  initial begin
    clk = 1'b0;
    forever #5ns clk = !clk;
  end

  task automatic write_cpsr(
    input logic [31:0] data,
    input logic [31:0] mask
  );
    @(negedge clk);
    cpsr_write_enable = 1'b1;
    cpsr_write_data   = data;
    cpsr_write_mask   = mask;
    @(negedge clk);
    cpsr_write_enable = 1'b0;
  endtask

  task automatic write_spsr(
    input arm9_mode_e mode,
    input logic [31:0] data,
    input logic [31:0] mask
  );
    @(negedge clk);
    spsr_write_enable = 1'b1;
    spsr_write_mode   = mode;
    spsr_write_data   = data;
    spsr_write_mask   = mask;
    @(negedge clk);
    spsr_write_enable = 1'b0;
  endtask

  task automatic expect_spsr(
    input arm9_mode_e mode,
    input logic [31:0] tdmi_expected,
    input logic [31:0] arm946_expected
  );
    spsr_read_mode = mode;
    #1ns;
    assert (tdmi_spsr_read_valid);
    assert (arm946_spsr_read_valid);
    assert (tdmi_spsr_read_value == tdmi_expected) else begin
      $error(
        "TDMI SPSR_%02x expected=%08x actual=%08x",
        mode,
        tdmi_expected,
        tdmi_spsr_read_value
      );
    end
    assert (arm946_spsr_read_value == arm946_expected) else begin
      $error(
        "ARM946 SPSR_%02x expected=%08x actual=%08x",
        mode,
        arm946_expected,
        arm946_spsr_read_value
      );
    end
  endtask

  initial begin
    reset              = 1'b1;
    cpsr_write_enable  = 1'b0;
    cpsr_write_data    = '0;
    cpsr_write_mask    = '0;
    spsr_read_mode     = ARM9_MODE_SUPERVISOR;
    spsr_write_enable  = 1'b0;
    spsr_write_mode    = ARM9_MODE_SUPERVISOR;
    spsr_write_data    = '0;
    spsr_write_mask    = '0;

    // REQ: ARM9TDMI-RESET-CPSR-001
    // REQ: ARM946ES-RESET-CPSR-001
    @(negedge clk);
    reset = 1'b0;
    #1ns;
    assert (tdmi_cpsr_value[7:0] == 8'hd3);
    assert (arm946_cpsr_value[7:0] == 8'hd3);
    assert (tdmi_current_mode == ARM9_MODE_SUPERVISOR);
    assert (arm946_current_mode == ARM9_MODE_SUPERVISOR);

    // REQ: COMMON-PSR-RESERVED-001
    // REQ: ARM9TDMI-PSR-Q-001
    // REQ: ARM946ES-PSR-Q-001
    write_cpsr(32'hffff_ffff, 32'hffff_ffff);
    #1ns;
    assert (tdmi_cpsr_value == 32'hf000_00ff);
    assert (arm946_cpsr_value == 32'hf800_00ff);
    assert (tdmi_current_mode == ARM9_MODE_SYSTEM);
    assert (arm946_current_mode == ARM9_MODE_SYSTEM);

    write_cpsr(32'h0000_0013, 32'h0000_001f);
    #1ns;
    assert (tdmi_cpsr_value == 32'hf000_00f3);
    assert (arm946_cpsr_value == 32'hf800_00f3);

    // REQ: COMMON-PSR-BANKING-001
    write_spsr(ARM9_MODE_FIQ, 32'h1800_00d1, 32'hffff_ffff);
    write_spsr(ARM9_MODE_IRQ, 32'h2800_00d2, 32'hffff_ffff);
    write_spsr(ARM9_MODE_SUPERVISOR, 32'h4800_00d3, 32'hffff_ffff);
    write_spsr(ARM9_MODE_ABORT, 32'h8800_00d7, 32'hffff_ffff);
    write_spsr(ARM9_MODE_UNDEFINED, 32'hf800_00db, 32'hffff_ffff);

    expect_spsr(ARM9_MODE_FIQ, 32'h1000_00d1, 32'h1800_00d1);
    expect_spsr(ARM9_MODE_IRQ, 32'h2000_00d2, 32'h2800_00d2);
    expect_spsr(ARM9_MODE_SUPERVISOR, 32'h4000_00d3, 32'h4800_00d3);
    expect_spsr(ARM9_MODE_ABORT, 32'h8000_00d7, 32'h8800_00d7);
    expect_spsr(ARM9_MODE_UNDEFINED, 32'hf000_00db, 32'hf800_00db);

    spsr_read_mode = ARM9_MODE_USER;
    #1ns;
    assert (!tdmi_spsr_read_valid);
    assert (!arm946_spsr_read_valid);
    spsr_read_mode = ARM9_MODE_SYSTEM;
    #1ns;
    assert (!tdmi_spsr_read_valid);
    assert (!arm946_spsr_read_valid);

    $display("PASS CPSR/SPSR profile masks, reset state, and all SPSR banks");
    $finish;
  end
endmodule
