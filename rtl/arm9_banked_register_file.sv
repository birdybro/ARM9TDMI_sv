module arm9_banked_register_file (
  input  logic                      clk,
  input  arm9_arch_pkg::arm9_mode_e read_mode_a,
  input  logic [3:0]                read_address_a,
  output logic [31:0]               read_data_a,
  input  arm9_arch_pkg::arm9_mode_e read_mode_b,
  input  logic [3:0]                read_address_b,
  output logic [31:0]               read_data_b,
  input  logic                      write_enable,
  input  arm9_arch_pkg::arm9_mode_e write_mode,
  input  logic [3:0]                write_address,
  input  logic [31:0]               write_data
);
  import arm9_arch_pkg::*;

  logic [31:0] registers_r0_r7 [0:7];
  logic [31:0] registers_r8_r12_user [0:4];
  logic [31:0] registers_r8_r12_fiq [0:4];
  logic [31:0] registers_r13_r14_user [0:1];
  logic [31:0] registers_r13_r14_fiq [0:1];
  logic [31:0] registers_r13_r14_irq [0:1];
  logic [31:0] registers_r13_r14_supervisor [0:1];
  logic [31:0] registers_r13_r14_abort [0:1];
  logic [31:0] registers_r13_r14_undefined [0:1];

  function automatic logic [31:0] read_physical_register(
    input arm9_mode_e logical_mode,
    input logic [3:0] logical_address
  );
    if (logical_address <= 4'd7) begin
      return registers_r0_r7[logical_address[2:0]];
    end
    if (logical_address <= 4'd12) begin
      if (logical_mode == ARM9_MODE_FIQ) begin
        return registers_r8_r12_fiq[logical_address[2:0]];
      end
      return registers_r8_r12_user[logical_address[2:0]];
    end
    if (logical_address <= 4'd14) begin
      case (logical_mode)
        ARM9_MODE_FIQ: return registers_r13_r14_fiq[logical_address[0]];
        ARM9_MODE_IRQ: return registers_r13_r14_irq[logical_address[0]];
        ARM9_MODE_SUPERVISOR: begin
          return registers_r13_r14_supervisor[logical_address[0]];
        end
        ARM9_MODE_ABORT: begin
          return registers_r13_r14_abort[logical_address[0]];
        end
        ARM9_MODE_UNDEFINED: begin
          return registers_r13_r14_undefined[logical_address[0]];
        end
        default: return registers_r13_r14_user[logical_address[0]];
      endcase
    end
    return 'x;
  endfunction

  always_comb begin
    read_data_a = read_physical_register(read_mode_a, read_address_a);
    read_data_b = read_physical_register(read_mode_b, read_address_b);
  end

  always_ff @(posedge clk) begin
    if (write_enable) begin
      if (write_address <= 4'd7) begin
        registers_r0_r7[write_address[2:0]] <= write_data;
      end else if (write_address <= 4'd12) begin
        if (write_mode == ARM9_MODE_FIQ) begin
          registers_r8_r12_fiq[write_address[2:0]] <= write_data;
        end else begin
          registers_r8_r12_user[write_address[2:0]] <= write_data;
        end
      end else if (write_address <= 4'd14) begin
        case (write_mode)
          ARM9_MODE_FIQ: begin
            registers_r13_r14_fiq[write_address[0]] <= write_data;
          end
          ARM9_MODE_IRQ: begin
            registers_r13_r14_irq[write_address[0]] <= write_data;
          end
          ARM9_MODE_SUPERVISOR: begin
            registers_r13_r14_supervisor[write_address[0]] <= write_data;
          end
          ARM9_MODE_ABORT: begin
            registers_r13_r14_abort[write_address[0]] <= write_data;
          end
          ARM9_MODE_UNDEFINED: begin
            registers_r13_r14_undefined[write_address[0]] <= write_data;
          end
          default: begin
            registers_r13_r14_user[write_address[0]] <= write_data;
          end
        endcase
      end
    end
  end

`ifndef SYNTHESIS
  always_ff @(posedge clk) begin
    assert (mode_is_valid(read_mode_a));
    assert (mode_is_valid(read_mode_b));
    if (write_enable) begin
      assert (mode_is_valid(write_mode));
      assert (write_address < 4'd15);
    end
  end
`endif
endmodule
