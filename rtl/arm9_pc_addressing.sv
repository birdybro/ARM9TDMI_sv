module arm9_pc_addressing (
  input  logic [31:0] instruction_address,
  input  logic        thumb_state,
  input  logic [31:0] write_value,
  input  logic        exchange_state,
  output logic [31:0] pc_read_value,
  output logic [31:0] write_target,
  output logic        write_thumb_state,
  output logic        unpredictable_alignment
);
  always_comb begin
    if (thumb_state) begin
      pc_read_value = instruction_address + 32'd4;
    end else begin
      pc_read_value = instruction_address + 32'd8;
    end

    if (exchange_state) begin
      write_target            = {write_value[31:1], 1'b0};
      write_thumb_state       = write_value[0];
      unpredictable_alignment = !write_value[0] && write_value[1];
    end else if (thumb_state) begin
      write_target            = {write_value[31:1], 1'b0};
      write_thumb_state       = 1'b1;
      unpredictable_alignment = 1'b0;
    end else begin
      write_target            = write_value;
      write_thumb_state       = 1'b0;
      unpredictable_alignment = |write_value[1:0];
    end
  end

`ifndef SYNTHESIS
  always_comb begin
    if (thumb_state) begin
      assert (instruction_address[0] == 1'b0);
    end else begin
      assert (instruction_address[1:0] == 2'b00);
    end
  end
`endif
endmodule
