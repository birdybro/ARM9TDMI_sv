module pc_addressing_tb;
  logic [31:0] instruction_address;
  logic        thumb_state;
  logic [31:0] write_value;
  logic        exchange_state;
  logic [31:0] pc_read_value;
  logic [31:0] write_target;
  logic        write_thumb_state;
  logic        unpredictable_alignment;
  int unsigned cases_checked;

  arm9_pc_addressing dut (.*);

  initial begin
    instruction_address = 32'h0000_1000;
    thumb_state          = 1'b0;
    write_value          = '0;
    exchange_state       = 1'b0;
    cases_checked        = 0;

    // REQ: COMMON-PC-READ-001
    for (int unsigned address = 0; address < 256; address += 4) begin
      instruction_address = {24'h123456, address[7:0]};
      thumb_state = 1'b0;
      #1ps;
      assert (pc_read_value == instruction_address + 32'd8);
      cases_checked++;
    end
    for (int unsigned address = 0; address < 256; address += 2) begin
      instruction_address = {24'habcdef, address[7:0]};
      thumb_state = 1'b1;
      #1ps;
      assert (pc_read_value == instruction_address + 32'd4);
      cases_checked++;
    end

    // REQ: COMMON-PC-WRITE-001
    instruction_address = 32'h0000_1000;
    for (int unsigned low_bits = 0; low_bits < 4; low_bits++) begin
      thumb_state    = 1'b0;
      exchange_state = 1'b0;
      write_value     = 32'h2468_ace0 | low_bits;
      #1ps;
      assert (write_target == write_value);
      assert (!write_thumb_state);
      assert (unpredictable_alignment == (low_bits != 0));
      cases_checked++;

      thumb_state = 1'b1;
      #1ps;
      assert (write_target == {write_value[31:1], 1'b0});
      assert (write_thumb_state);
      assert (!unpredictable_alignment);
      cases_checked++;
    end

    // REQ: COMMON-PC-BX-001
    exchange_state = 1'b1;
    for (int unsigned low_bits = 0; low_bits < 4; low_bits++) begin
      write_value = 32'h1357_9bd0 | low_bits;
      #1ps;
      assert (write_target == {write_value[31:1], 1'b0});
      assert (write_thumb_state == write_value[0]);
      assert (unpredictable_alignment ==
              (!write_value[0] && write_value[1]));
      cases_checked++;
    end

    assert (cases_checked == 204);
    $display("PASS ARM/Thumb PC reads, ordinary writes, and BX target rules");
    $finish;
  end
endmodule
