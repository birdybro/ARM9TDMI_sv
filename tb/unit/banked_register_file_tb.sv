module banked_register_file_tb;
  import arm9_arch_pkg::*;

  logic       clk;
  arm9_mode_e read_mode_a;
  logic [3:0] read_address_a;
  logic [31:0] read_data_a;
  arm9_mode_e read_mode_b;
  logic [3:0] read_address_b;
  logic [31:0] read_data_b;
  logic       write_enable;
  arm9_mode_e write_mode;
  logic [3:0] write_address;
  logic [31:0] write_data;

  arm9_banked_register_file dut (.*);

  initial begin
    clk = 1'b0;
    forever #5ns clk = !clk;
  end

  task automatic write_register(
    input arm9_mode_e mode,
    input logic [3:0] address,
    input logic [31:0] data
  );
    @(negedge clk);
    write_enable  = 1'b1;
    write_mode    = mode;
    write_address = address;
    write_data    = data;
    @(negedge clk);
    write_enable  = 1'b0;
  endtask

  task automatic expect_register(
    input arm9_mode_e mode,
    input logic [3:0] address,
    input logic [31:0] expected
  );
    read_mode_a    = mode;
    read_address_a = address;
    #1ns;
    assert (read_data_a == expected) else begin
      $error(
        "mode=%02x R%0d expected=%08x actual=%08x",
        mode,
        address,
        expected,
        read_data_a
      );
    end
  endtask

  initial begin
    write_enable  = 1'b0;
    write_mode    = ARM9_MODE_USER;
    write_address = '0;
    write_data    = '0;
    read_mode_a   = ARM9_MODE_USER;
    read_address_a = '0;
    read_mode_b   = ARM9_MODE_USER;
    read_address_b = '0;

    // REQ: COMMON-MODE-ENCODING-001
    assert (mode_is_valid(ARM9_MODE_USER));
    assert (mode_is_valid(ARM9_MODE_FIQ));
    assert (mode_is_valid(ARM9_MODE_IRQ));
    assert (mode_is_valid(ARM9_MODE_SUPERVISOR));
    assert (mode_is_valid(ARM9_MODE_ABORT));
    assert (mode_is_valid(ARM9_MODE_UNDEFINED));
    assert (mode_is_valid(ARM9_MODE_SYSTEM));
    assert (!mode_is_valid(arm9_mode_e'(5'b00000)));
    assert (!mode_is_privileged(ARM9_MODE_USER));
    assert (mode_is_privileged(ARM9_MODE_SYSTEM));
    assert (!mode_has_spsr(ARM9_MODE_USER));
    assert (!mode_has_spsr(ARM9_MODE_SYSTEM));
    assert (mode_has_spsr(ARM9_MODE_FIQ));
    assert (mode_has_spsr(ARM9_MODE_IRQ));
    assert (mode_has_spsr(ARM9_MODE_SUPERVISOR));
    assert (mode_has_spsr(ARM9_MODE_ABORT));
    assert (mode_has_spsr(ARM9_MODE_UNDEFINED));

    // REQ: COMMON-REG-BANKING-001
    for (int unsigned address = 0; address < 8; address++) begin
      write_register(ARM9_MODE_USER, address[3:0], 32'h1000_0000 + address);
      expect_register(ARM9_MODE_FIQ, address[3:0], 32'h1000_0000 + address);
      expect_register(ARM9_MODE_SYSTEM, address[3:0], 32'h1000_0000 + address);
    end

    // REQ: COMMON-REG-BANKING-002
    for (int unsigned address = 8; address < 13; address++) begin
      write_register(ARM9_MODE_USER, address[3:0], 32'h2000_0000 + address);
      write_register(ARM9_MODE_FIQ, address[3:0], 32'h2100_0000 + address);
      expect_register(ARM9_MODE_IRQ, address[3:0], 32'h2000_0000 + address);
      expect_register(ARM9_MODE_SYSTEM, address[3:0], 32'h2000_0000 + address);
      expect_register(ARM9_MODE_FIQ, address[3:0], 32'h2100_0000 + address);
    end

    // REQ: COMMON-REG-BANKING-003
    for (int unsigned address = 13; address < 15; address++) begin
      write_register(ARM9_MODE_USER, address[3:0], 32'h3000_0000 + address);
      write_register(ARM9_MODE_FIQ, address[3:0], 32'h3100_0000 + address);
      write_register(ARM9_MODE_IRQ, address[3:0], 32'h3200_0000 + address);
      write_register(ARM9_MODE_SUPERVISOR, address[3:0], 32'h3300_0000 + address);
      write_register(ARM9_MODE_ABORT, address[3:0], 32'h3400_0000 + address);
      write_register(ARM9_MODE_UNDEFINED, address[3:0], 32'h3500_0000 + address);

      expect_register(ARM9_MODE_USER, address[3:0], 32'h3000_0000 + address);
      expect_register(ARM9_MODE_SYSTEM, address[3:0], 32'h3000_0000 + address);
      expect_register(ARM9_MODE_FIQ, address[3:0], 32'h3100_0000 + address);
      expect_register(ARM9_MODE_IRQ, address[3:0], 32'h3200_0000 + address);
      expect_register(ARM9_MODE_SUPERVISOR, address[3:0], 32'h3300_0000 + address);
      expect_register(ARM9_MODE_ABORT, address[3:0], 32'h3400_0000 + address);
      expect_register(ARM9_MODE_UNDEFINED, address[3:0], 32'h3500_0000 + address);
    end

    read_mode_a    = ARM9_MODE_FIQ;
    read_address_a = 4'd10;
    read_mode_b    = ARM9_MODE_IRQ;
    read_address_b = 4'd14;
    #1ns;
    assert (read_data_a == 32'h2100_000a);
    assert (read_data_b == 32'h3200_000e);

    $display("PASS all ARM register banks and mode encodings");
    $finish;
  end
endmodule
